using System;
using System.IO;
using System.Net;
using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Security;
using System.Security.Cryptography;
using System.Security.Cryptography.Pkcs;
using System.Security.Cryptography.X509Certificates;
using System.Security.Permissions;
using System.Security.Principal;
using System.Text.RegularExpressions;
using Ionic.Zip;
using Microsoft.Win32.SafeHandles;
using WKISigner.Properties;

namespace WKISigner;

public static class CertHelper
{
	public enum CLRVerification
	{
		OnLine,
		OffLine
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct CERT_CHAIN_ENGINE_CONFIG_WINXP
	{
		public uint cbSize;

		public SafeCertStoreHandle hRestrictedRoot;

		public SafeCertStoreHandle hRestrictedTrust;

		public SafeCertStoreHandle hRestrictedOther;

		public uint cAdditionalStore;

		public IntPtr rghAdditionalStore;

		public uint dwFlags;

		public uint dwUrlRetrievalTimeout;

		public uint MaximumCachedCertificates;

		public uint CycleDetectionModulus;
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct CERT_CHAIN_ENGINE_CONFIG_WIN7
	{
		public uint cbSize;

		public SafeCertStoreHandle hRestrictedRoot;

		public SafeCertStoreHandle hRestrictedTrust;

		public SafeCertStoreHandle hRestrictedOther;

		public uint cAdditionalStore;

		public IntPtr rghAdditionalStore;

		public uint dwFlags;

		public uint dwUrlRetrievalTimeout;

		public uint MaximumCachedCertificates;

		public uint CycleDetectionModulus;

		public SafeCertStoreHandle hExclusiveRoot;

		public SafeCertStoreHandle hExclusiveTrustedPeople;
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct CERT_CHAIN_POLICY_STATUS
	{
		public uint cbSize;

		public uint dwError;

		public IntPtr lChainIndex;

		public IntPtr lElementIndex;

		public IntPtr pvExtraPolicyStatus;
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct CERT_CHAIN_PARA
	{
		public uint cbSize;

		public CERT_USAGE_MATCH RequestedUsage;

		public CERT_USAGE_MATCH RequestedIssuancePolicy;

		public uint dwUrlRetrievalTimeout;

		public bool fCheckRevocationFreshnessTime;

		public uint dwRevocationFreshnessTime;
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct CERT_USAGE_MATCH
	{
		public uint dwType;

		public CERT_ENHKEY_USAGE Usage;
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct CERT_ENHKEY_USAGE
	{
		public uint cUsageIdentifier;

		public IntPtr rgpszUsageIdentifier;
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct CERT_CHAIN_POLICY_PARA
	{
		public uint cbSize;

		public uint dwFlags;

		public IntPtr pvExtraPolicyPara;
	}

	private class SafeCertContextHandle : SafeHandleZeroOrMinusOneIsInvalid
	{
		public static SafeCertContextHandle InvalidHandle => new SafeCertContextHandle(IntPtr.Zero);

		private SafeCertContextHandle()
			: base(ownsHandle: true)
		{
		}

		public SafeCertContextHandle(IntPtr handle)
			: base(ownsHandle: true)
		{
			SetHandle(handle);
		}

		[DllImport("crypt32.dll", SetLastError = true)]
		[SuppressUnmanagedCodeSecurity]
		[ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
		private static extern bool CertFreeCertificateContext(IntPtr pCertContext);

		protected override bool ReleaseHandle()
		{
			return CertFreeCertificateContext(handle);
		}
	}

	private class SafeCertChainEngineHandle : SafeHandleZeroOrMinusOneIsInvalid
	{
		public static SafeCertChainEngineHandle InvalidHandle => new SafeCertChainEngineHandle(IntPtr.Zero);

		private SafeCertChainEngineHandle()
			: base(ownsHandle: true)
		{
		}

		public SafeCertChainEngineHandle(IntPtr handle)
			: base(ownsHandle: true)
		{
			SetHandle(handle);
		}

		[DllImport("crypt32.dll", SetLastError = true)]
		[SuppressUnmanagedCodeSecurity]
		[ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
		private static extern bool CertFreeCertificateChainEngine(IntPtr hChainEngine);

		protected override bool ReleaseHandle()
		{
			return CertFreeCertificateChainEngine(handle);
		}
	}

	private class SafeCertChainHandle : SafeHandleZeroOrMinusOneIsInvalid
	{
		public static SafeCertChainHandle InvalidHandle => new SafeCertChainHandle(IntPtr.Zero);

		private SafeCertChainHandle()
			: base(ownsHandle: true)
		{
		}

		public SafeCertChainHandle(IntPtr handle)
			: base(ownsHandle: true)
		{
			SetHandle(handle);
		}

		[DllImport("crypt32.dll", SetLastError = true)]
		[SuppressUnmanagedCodeSecurity]
		[ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
		private static extern void CertFreeCertificateChain(IntPtr handle);

		protected override bool ReleaseHandle()
		{
			CertFreeCertificateChain(handle);
			return true;
		}
	}

	private class SafeCertStoreHandle : SafeHandleZeroOrMinusOneIsInvalid
	{
		public static SafeCertStoreHandle InvalidHandle => new SafeCertStoreHandle(IntPtr.Zero);

		private SafeCertStoreHandle()
			: base(ownsHandle: true)
		{
		}

		public SafeCertStoreHandle(IntPtr handle)
			: base(ownsHandle: true)
		{
			SetHandle(handle);
		}

		[DllImport("crypt32.dll", SetLastError = true)]
		[SuppressUnmanagedCodeSecurity]
		[ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
		private static extern bool CertCloseStore(IntPtr hCertStore, uint dwFlags);

		protected override bool ReleaseHandle()
		{
			return CertCloseStore(handle, 0u);
		}
	}

	internal static readonly bool LogEnabled = (Environment.GetEnvironmentVariable("WkiSignerLog") ?? "") == "1";

	private static readonly bool IsMoreThanVista = Environment.OSVersion.Platform == PlatformID.Win32NT && ((Environment.OSVersion.Version.Major == 6 && Environment.OSVersion.Version.Minor >= 1) || Environment.OSVersion.Version.Major > 6);

	[DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern SafeCertContextHandle CertDuplicateCertificateContext([In] IntPtr pCertContext);

	[DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern bool CertGetCertificateChain([In] SafeCertChainEngineHandle hChainEngine, [In] SafeCertContextHandle pCertContext, [In] ref System.Runtime.InteropServices.ComTypes.FILETIME pTime, [In] SafeCertStoreHandle hAdditionalStore, [In] ref CERT_CHAIN_PARA pChainPara, [In] uint dwFlags, [In] IntPtr pvReserved, [In][Out] ref SafeCertChainHandle ppChainContext);

	[DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern bool CertVerifyCertificateChainPolicy([In] IntPtr pszPolicyOID, [In] SafeCertChainHandle pChainContext, [In] ref CERT_CHAIN_POLICY_PARA pPolicyPara, [In][Out] ref CERT_CHAIN_POLICY_STATUS pPolicyStatus);

	[DllImport("crypt32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	private static extern bool CertCreateCertificateChainEngine([In] ref CERT_CHAIN_ENGINE_CONFIG_WINXP pConfig, [In][Out] ref SafeCertChainEngineHandle hCryptProvphChainEngine);

	[DllImport("crypt32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	private static extern bool CertCreateCertificateChainEngine([In] ref CERT_CHAIN_ENGINE_CONFIG_WIN7 pConfig, [In][Out] ref SafeCertChainEngineHandle hCryptProvphChainEngine);

	[DllImport("crypt32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	private static extern SafeCertStoreHandle CertOpenStore([In] IntPtr lpszStoreProvider, [In] uint dwMsgAndCertEncodingType, [In] IntPtr hCryptProv, [In] uint dwFlags, [In] string pvPara);

	[DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern bool CertAddCertificateLinkToStore([In] SafeCertStoreHandle hCertStore, [In] SafeCertContextHandle pCertContext, [In] uint dwAddDisposition, [In][Out] SafeCertContextHandle ppStoreContext);

	internal static X509Certificate2 ChooseCertificate(out bool noValidCertificateFound, IntPtr hWndParent)
	{
		Action<string> action = delegate
		{
		};
		if (LogEnabled)
		{
			action = delegate(string s)
			{
				File.AppendAllText(".\\WKISigner.log", DateTime.Now.ToString() + " " + s + "\r\n");
			};
		}
		X509Certificate2Collection x509Certificate2Collection = new X509Certificate2Collection();
		X509Store x509Store = new X509Store(StoreName.My, StoreLocation.CurrentUser);
		try
		{
			x509Store.Open(OpenFlags.ReadOnly);
			action("All certificates in (CurrentUser) " + WindowsIdentity.GetCurrent().Name + " /My: ");
			X509Certificate2Enumerator enumerator = x509Store.Certificates.GetEnumerator();
			while (enumerator.MoveNext())
			{
				X509Certificate2 current = enumerator.Current;
				if (current == null)
				{
					continue;
				}
				action($"  {current.SubjectName.Name} thumbprint: {current.Thumbprint}");
				X509ExtensionEnumerator enumerator2 = current.Extensions.GetEnumerator();
				while (enumerator2.MoveNext())
				{
					X509Extension current2 = enumerator2.Current;
					action($"    Oid : {current2.Oid.Value}");
					if (current2.Oid.Value == "2.5.29.15")
					{
						X509KeyUsageExtension x509KeyUsageExtension = (X509KeyUsageExtension)current2;
						bool flag = x509KeyUsageExtension.KeyUsages == X509KeyUsageFlags.NonRepudiation;
						action(string.Format("    Usage:    {0} - {1}", flag ? "OK" : "KO", x509KeyUsageExtension.KeyUsages));
						bool flag2 = current.NotAfter > DateTime.Now;
						action(string.Format("    NotAfter: {0} - {1}", flag2 ? "OK" : "KO", current.NotAfter));
						bool hasPrivateKey = current.HasPrivateKey;
						action(string.Format("    HasPK:    {0} - {1}", hasPrivateKey ? "OK" : "KO", current.HasPrivateKey));
						bool flag3 = current.SignatureAlgorithm.Value == "1.2.840.113549.1.1.11";
						action(string.Format("    SigAlg:   {0} - {1}", flag3 ? "OK" : "KO", current.SignatureAlgorithm.Value));
						bool flag4 = flag && flag2 && hasPrivateKey && flag3;
						if (flag4)
						{
							x509Certificate2Collection.Add(current);
						}
						action(string.Format("    {0} Issuer: {1}", flag4 ? "Added!" : "Skipped!", current.IssuerName.Name));
						break;
					}
				}
			}
		}
		finally
		{
			x509Store.Close();
		}
		noValidCertificateFound = x509Certificate2Collection.Count == 0;
		X509Certificate2Collection x509Certificate2Collection2 = X509Certificate2UI.SelectFromCollection(x509Certificate2Collection, "Certificati", "Scegliere con cosa firmare", X509SelectionFlag.SingleSelection, hWndParent);
		if (x509Certificate2Collection2.Count == 0)
		{
			action("Selected NO cert");
			return null;
		}
		X509Certificate2 x509Certificate = x509Certificate2Collection2[0];
		action($"Selected cert {x509Certificate.SubjectName.Name} thumbprint: {x509Certificate.Thumbprint} issuer: {x509Certificate.IssuerName.Name}");
		return x509Certificate;
	}

	internal static bool IsHardwareCertificate(X509Certificate2 cert)
	{
		Action<string> action = delegate
		{
		};
		if (LogEnabled)
		{
			action = delegate(string s)
			{
				File.AppendAllText(".\\WKISigner.log", DateTime.Now.ToString() + " " + s + "\r\n");
			};
		}
		RSACryptoServiceProvider rSACryptoServiceProvider = (RSACryptoServiceProvider)cert.PrivateKey;
		action($"***** certCSP.CspKeyContainerInfo.HardwareDevice --> {rSACryptoServiceProvider.CspKeyContainerInfo.HardwareDevice.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.Accessible --> {rSACryptoServiceProvider.CspKeyContainerInfo.Accessible.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.Exportable --> {rSACryptoServiceProvider.CspKeyContainerInfo.Exportable.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.KeyContainerName --> {rSACryptoServiceProvider.CspKeyContainerInfo.KeyContainerName.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.KeyNumber --> {rSACryptoServiceProvider.CspKeyContainerInfo.KeyNumber.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.MachineKeyStore --> {rSACryptoServiceProvider.CspKeyContainerInfo.MachineKeyStore.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.Protected --> {rSACryptoServiceProvider.CspKeyContainerInfo.Protected.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.ProviderName --> {rSACryptoServiceProvider.CspKeyContainerInfo.ProviderName.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.ProviderType --> {rSACryptoServiceProvider.CspKeyContainerInfo.ProviderType.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.RandomlyGenerated --> {rSACryptoServiceProvider.CspKeyContainerInfo.RandomlyGenerated.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.Removable --> {rSACryptoServiceProvider.CspKeyContainerInfo.Removable.ToString()}");
		action($"***** certCSP.CspKeyContainerInfo.UniqueKeyContainerName --> {rSACryptoServiceProvider.CspKeyContainerInfo.UniqueKeyContainerName.ToString()}");
		if (!rSACryptoServiceProvider.CspKeyContainerInfo.HardwareDevice)
		{
			if (rSACryptoServiceProvider.CspKeyContainerInfo.ProviderName.Contains("Bit4id"))
			{
				return rSACryptoServiceProvider.CspKeyContainerInfo.ProviderName.Contains("UKC");
			}
			return false;
		}
		return true;
	}

	public static void ShowCertificate(byte[] certificate)
	{
		ShowCertificate(certificate, IntPtr.Zero);
	}

	public static void ShowCertificate(byte[] certificate, IntPtr hWndParent)
	{
		X509Certificate2 x509Certificate = new X509Certificate2();
		x509Certificate.Import(certificate);
		X509Certificate2UI.DisplayCertificate(x509Certificate);
	}

	internal static void VerifyCertificate(X509Certificate2 certificate, X509RevocationMode revocationMode, DateTime verificationTime, string cnipaFilePath)
	{
		SafeCertContextHandle safeCertContextHandle = CertDuplicateCertificateContext(certificate.Handle);
		if (safeCertContextHandle == null || safeCertContextHandle.IsInvalid)
		{
			throw new ArgumentException("certificate");
		}
		new StorePermission(StorePermissionFlags.AllFlags).Assert();
		X509Certificate2Collection obj = (IsMoreThanVista ? loadCNIPACertificates(cnipaFilePath) : updateCNIPACertificateStore(cnipaFilePath));
		SafeCertStoreHandle safeCertStoreHandle = CertOpenStore(new IntPtr(2), 65537u, IntPtr.Zero, 8704u, null);
		if (safeCertStoreHandle == null || safeCertStoreHandle.IsInvalid)
		{
			throw new CryptographicException(Marshal.GetLastWin32Error());
		}
		X509Certificate2Enumerator enumerator = obj.GetEnumerator();
		while (enumerator.MoveNext())
		{
			SafeCertContextHandle safeCertContextHandle2 = CertDuplicateCertificateContext(enumerator.Current.Handle);
			if (safeCertContextHandle2 == null || safeCertContextHandle2.IsInvalid)
			{
				throw new CryptographicException(Marshal.GetLastWin32Error());
			}
			if (!CertAddCertificateLinkToStore(safeCertStoreHandle, safeCertContextHandle2, 2u, SafeCertContextHandle.InvalidHandle))
			{
				throw new CryptographicException(Marshal.GetLastWin32Error());
			}
		}
		SafeCertChainEngineHandle hCryptProvphChainEngine = SafeCertChainEngineHandle.InvalidHandle;
		bool flag;
		if (IsMoreThanVista)
		{
			CERT_CHAIN_ENGINE_CONFIG_WIN7 pConfig = new CERT_CHAIN_ENGINE_CONFIG_WIN7
			{
				cbSize = (uint)Marshal.SizeOf(typeof(CERT_CHAIN_ENGINE_CONFIG_WIN7)),
				hRestrictedRoot = SafeCertStoreHandle.InvalidHandle,
				hRestrictedTrust = SafeCertStoreHandle.InvalidHandle,
				hRestrictedOther = SafeCertStoreHandle.InvalidHandle,
				cAdditionalStore = 0u,
				rghAdditionalStore = IntPtr.Zero,
				dwFlags = 17u,
				dwUrlRetrievalTimeout = 0u,
				MaximumCachedCertificates = 0u,
				CycleDetectionModulus = 0u,
				hExclusiveRoot = safeCertStoreHandle,
				hExclusiveTrustedPeople = SafeCertStoreHandle.InvalidHandle
			};
			flag = CertCreateCertificateChainEngine(ref pConfig, ref hCryptProvphChainEngine);
		}
		else
		{
			SafeCertStoreHandle safeCertStoreHandle2 = CertOpenStore(new IntPtr(2), 0u, IntPtr.Zero, 0u, null);
			if (safeCertStoreHandle2 == null || safeCertStoreHandle2.IsInvalid)
			{
				throw new CryptographicException(Marshal.GetLastWin32Error());
			}
			CERT_CHAIN_ENGINE_CONFIG_WINXP pConfig2 = new CERT_CHAIN_ENGINE_CONFIG_WINXP
			{
				cbSize = (uint)Marshal.SizeOf(typeof(CERT_CHAIN_ENGINE_CONFIG_WINXP)),
				hRestrictedRoot = safeCertStoreHandle,
				hRestrictedTrust = safeCertStoreHandle2,
				hRestrictedOther = safeCertStoreHandle2,
				cAdditionalStore = 0u,
				rghAdditionalStore = IntPtr.Zero,
				dwFlags = 17u,
				dwUrlRetrievalTimeout = 0u,
				MaximumCachedCertificates = 0u,
				CycleDetectionModulus = 0u
			};
			flag = CertCreateCertificateChainEngine(ref pConfig2, ref hCryptProvphChainEngine);
		}
		if (!flag || hCryptProvphChainEngine == null || hCryptProvphChainEngine.IsInvalid)
		{
			throw new CryptographicException(Marshal.GetLastWin32Error());
		}
		CERT_CHAIN_PARA pChainPara = default(CERT_CHAIN_PARA);
		pChainPara.cbSize = (uint)Marshal.SizeOf(pChainPara);
		pChainPara.dwUrlRetrievalTimeout = 30000u;
		System.Runtime.InteropServices.ComTypes.FILETIME pTime = new System.Runtime.InteropServices.ComTypes.FILETIME
		{
			dwLowDateTime = (int)(verificationTime.ToFileTime() & 0xFFFFFFFFu),
			dwHighDateTime = (int)(verificationTime.ToFileTime() >> 32)
		};
		uint num = 0u;
		if (revocationMode != X509RevocationMode.NoCheck)
		{
			num = 671089152u;
			if (revocationMode == X509RevocationMode.Offline)
			{
				num |= 0x80000000u;
			}
		}
		SafeCertChainHandle ppChainContext = SafeCertChainHandle.InvalidHandle;
		if (!CertGetCertificateChain(hCryptProvphChainEngine, safeCertContextHandle, ref pTime, SafeCertStoreHandle.InvalidHandle, ref pChainPara, num, IntPtr.Zero, ref ppChainContext))
		{
			throw new CryptographicException(Marshal.GetHRForLastWin32Error());
		}
		CERT_CHAIN_POLICY_PARA pPolicyPara = new CERT_CHAIN_POLICY_PARA
		{
			cbSize = (uint)Marshal.SizeOf(typeof(CERT_CHAIN_POLICY_PARA)),
			dwFlags = 0u,
			pvExtraPolicyPara = IntPtr.Zero
		};
		CERT_CHAIN_POLICY_STATUS pPolicyStatus = new CERT_CHAIN_POLICY_STATUS
		{
			cbSize = (uint)Marshal.SizeOf(typeof(CERT_CHAIN_POLICY_STATUS))
		};
		if (CertVerifyCertificateChainPolicy(new IntPtr(1L), ppChainContext, ref pPolicyPara, ref pPolicyStatus))
		{
			if (pPolicyStatus.dwError != 0)
			{
				throw new CryptographicException((int)pPolicyStatus.dwError);
			}
			return;
		}
		throw new CryptographicException(Marshal.GetHRForLastWin32Error());
	}

	internal static void IsSignerCertificate(X509Certificate2 certificate)
	{
		if (certificate.Issuer == null)
		{
			throw new CryptographicException("Il certificato manca del campo \"Issuer\".");
		}
		if (!Regex.IsMatch(certificate.Issuer, "C=\\w+", RegexOptions.IgnoreCase))
		{
			throw new CryptographicException("Il certificato manca dell'attributo \"countryName\" nel campo \"Issuer\".");
		}
		if (!Regex.IsMatch(certificate.Issuer, "O=\\w+", RegexOptions.IgnoreCase))
		{
			throw new CryptographicException("Il certificato manca dell'attributo \"organizationName\" nel campo \"Issuer\".");
		}
		if (certificate.Subject == null)
		{
			throw new CryptographicException("Il certificato manca del campo \"Subject\".");
		}
		if (!Regex.IsMatch(certificate.Subject, "pseudonym=\\w+", RegexOptions.IgnoreCase))
		{
			if (!Regex.IsMatch(certificate.Subject, "G=\\w+", RegexOptions.IgnoreCase))
			{
				throw new CryptographicException("Il certificato manca dell'attributo \"givenName\" nel campo \"Subject\".");
			}
			if (!Regex.IsMatch(certificate.Subject, "SN=\\w+", RegexOptions.IgnoreCase))
			{
				throw new CryptographicException("Il certificato manca dell'attributo \"surname\" nel campo \"Subject\".");
			}
			if (!Regex.IsMatch(certificate.Subject, "C=\\w+", RegexOptions.IgnoreCase))
			{
				throw new CryptographicException("Il certificato manca dell'attributo \"countryName\" nel campo \"Subject\".");
			}
			if (!Regex.IsMatch(certificate.Subject, "O=\\w+", RegexOptions.IgnoreCase))
			{
				throw new CryptographicException("Il certificato manca dell'attributo \"organizationName\" nel campo \"Subject\".");
			}
			if (!Regex.IsMatch(certificate.Subject, "serialNumber=\\w+", RegexOptions.IgnoreCase))
			{
				throw new CryptographicException("Il certificato manca dell'attributo \"serialNumber\" nel campo \"Subject\".");
			}
			if (!Regex.IsMatch(certificate.Subject, "dnQualifier=\\w+", RegexOptions.IgnoreCase))
			{
				throw new CryptographicException("Il certificato manca dell'attributo \"dnQualifier\" nel campo \"Subject\".");
			}
			if (Regex.Matches(certificate.Subject, "OU=\\w+", RegexOptions.IgnoreCase).Count > 5)
			{
				throw new CryptographicException("Il certificato contiene l'attributo \"organizationalUnitName\" più di 5 volte nel campo \"Subject\".");
			}
			bool flag = false;
			bool flag2 = false;
			bool flag3 = false;
			bool flag4 = false;
			bool flag5 = false;
			bool flag6 = false;
			X509ExtensionEnumerator enumerator = certificate.Extensions.GetEnumerator();
			while (enumerator.MoveNext())
			{
				X509Extension current = enumerator.Current;
				switch (current.Oid.Value)
				{
				case "2.5.29.15":
				{
					flag = true;
					X509KeyUsageExtension x509KeyUsageExtension = new X509KeyUsageExtension();
					x509KeyUsageExtension.CopyFrom(current);
					if (!x509KeyUsageExtension.KeyUsages.Equals(X509KeyUsageFlags.NonRepudiation))
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"KeyUsage\" contenente \"NonRepudiation\".");
					}
					if (!x509KeyUsageExtension.Critical)
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"KeyUsage\" marcata critica.");
					}
					break;
				}
				case "2.5.29.32":
					flag2 = true;
					if (!Regex.IsMatch(current.Format(multiLine: false), "=([0-9]+\\.?)+.+=CPS.+(http|ftp)://", RegexOptions.IgnoreCase))
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"certificatePolicies\" correttamente valorizzata; deve contenere l'OID della Certificate Policy e l'URL che punta al Certificate Practice Statement (CPS).");
					}
					if (current.Critical)
					{
						throw new CryptographicException("Il certificato ha erroneamente l'estensione \"certificatePolicies\" marcata critica.");
					}
					break;
				case "2.5.29.31":
					if (Regex.IsMatch(current.Format(multiLine: false), "CRL.+=(http|ldap)://", RegexOptions.IgnoreCase))
					{
						flag3 = true;
					}
					if (current.Critical)
					{
						throw new CryptographicException("Il certificato ha erroneamente l'estensione \"crlDistributionPoints\" marcata critica.");
					}
					break;
				case "2.5.29.35":
					flag4 = true;
					try
					{
						int num5 = ASN1DERHelper.SequenceFirstTagPosition(current.RawData, 0);
						if (current.RawData[num5] != 128)
						{
							throw new Exception();
						}
						if (ASN1DERHelper.TagValueLenght(current.RawData, num5) == 0)
						{
							throw new Exception();
						}
					}
					catch
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"authorityKeyIdentifier\" correttamente valorizzata; deve contenere almeno il campo keyIdentifier.");
					}
					if (current.Critical)
					{
						throw new CryptographicException("Il certificato ha erroneamente l'estensione \"authorityKeyIdentifier\" marcata critica.");
					}
					break;
				case "2.5.29.14":
					flag5 = true;
					if (string.IsNullOrEmpty(current.Format(multiLine: false)))
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"subjectKeyIdentifier\" correttamente valorizzata; deve contenere il keyIdentifier.");
					}
					if (current.Critical)
					{
						throw new CryptographicException("Il certificato ha erroneamente l'estensione \"subjectKeyIdentifier\" marcata critica.");
					}
					break;
				case "1.3.6.1.5.5.7.1.3":
				{
					flag6 = true;
					bool flag7 = false;
					bool flag8 = false;
					bool flag9 = false;
					try
					{
						for (int num = ASN1DERHelper.SequenceFirstTagPosition(current.RawData, 0); num != -1; num = ASN1DERHelper.NextTagPosition(current.RawData, num))
						{
							int num2 = ASN1DERHelper.SequenceFirstTagPosition(current.RawData, num);
							if (ASN1DERHelper.IsOID("0.4.0.1862.1.1", current.RawData, num2))
							{
								flag7 = true;
							}
							else if (ASN1DERHelper.IsOID("0.4.0.1862.1.3", current.RawData, num2))
							{
								byte[] array = ASN1DERHelper.TagValue(current.RawData, ASN1DERHelper.NextTagPosition(current.RawData, num2));
								if (array[0] < 128)
								{
									if (array[0] == 0)
									{
										Array.Reverse(array, 1, array.Length - 1);
									}
									else
									{
										Array.Reverse(array, 0, array.Length);
									}
									int num3 = 0;
									for (int i = 0; i < array.Length; i++)
									{
										int num4 = 1;
										for (int j = 1; j <= i; j++)
										{
											num4 *= 256;
										}
										num3 += array[i] * num4;
									}
									if (num3 >= 20)
									{
										flag8 = true;
									}
								}
							}
							else if (ASN1DERHelper.IsOID("0.4.0.1862.1.4", current.RawData, num2))
							{
								flag9 = true;
							}
						}
					}
					catch
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"qcStatements\" correttamente valorizzata.");
					}
					if (!flag7)
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"qcStatements\" correttamente valorizzata, id-etsi-qcs-QcCompliance assente o errato.");
					}
					if (!flag8)
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"qcStatements\" correttamente valorizzata, id-etsi-qcs-QcRetentionPeriod assente o errato.");
					}
					if (!flag9)
					{
						throw new CryptographicException("Il certificato non ha l'estensione \"qcStatements\" correttamente valorizzata, id-etsi-qcs-QcSSCD assente o errato.");
					}
					if (current.Critical)
					{
						throw new CryptographicException("Il certificato ha erroneamente l'estensione \"qcStatements\" marcata critica.");
					}
					break;
				}
				default:
					if (current.Critical)
					{
						throw new CryptographicException("Il certificato ha erroneamente l'estensione \"" + current.Oid.FriendlyName + "\" (" + current.Oid.Value + ") marcata critica.");
					}
					break;
				}
			}
			if (!flag)
			{
				throw new CryptographicException("Il certificato non ha l'estensione \"KeyUsage\".");
			}
			if (!flag2)
			{
				throw new CryptographicException("Il certificato non ha l'estensione \"certificatePolicies\".");
			}
			if (!flag3)
			{
				throw new CryptographicException("Il certificato non ha l'estensione \"crlDistributionPoints\",  oppure non è correttamente valorizzata; deve essere presente l'URL HTTP oppure LDAP per consentire lo scaricamento anonimo della CRL.");
			}
			if (!flag4)
			{
				throw new CryptographicException("Il certificato non ha l'estensione \"authorityKeyIdentifier\".");
			}
			if (!flag5)
			{
				throw new CryptographicException("Il certificato non ha l'estensione \"subjectKeyIdentifier\".");
			}
			if (!flag6)
			{
				throw new CryptographicException("Il certificato non ha l'estensione \"qcStatements\".");
			}
			if (certificate.PublicKey == null)
			{
				throw new CryptographicException("Il certificato non ha la chiave pubblica.");
			}
			_ = certificate.NotBefore;
			_ = certificate.NotAfter;
			if (string.IsNullOrEmpty(certificate.SerialNumber))
			{
				throw new CryptographicException("Il certificato manca del numero seriale.");
			}
			return;
		}
		throw new CryptographicException("Il certificato manca dell'attributo \"pseudonym\", o in alternativa, degli attributi \"givenName\" e \"surname\" nel campo \"Subject\".");
	}

	internal static void IsTimestampCertificate(X509Certificate2 certificate)
	{
		bool flag = false;
		bool flag2 = false;
		bool flag3 = false;
		bool flag4 = false;
		bool flag5 = false;
		X509ExtensionEnumerator enumerator = certificate.Extensions.GetEnumerator();
		while (enumerator.MoveNext())
		{
			X509Extension current = enumerator.Current;
			switch (current.Oid.Value)
			{
			case "2.5.29.15":
			{
				flag = true;
				X509KeyUsageExtension x509KeyUsageExtension = new X509KeyUsageExtension();
				x509KeyUsageExtension.CopyFrom(current);
				if (!x509KeyUsageExtension.KeyUsages.Equals(X509KeyUsageFlags.DigitalSignature))
				{
					throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"KeyUsage\" contenente \"DigitalSignature\".");
				}
				if (!x509KeyUsageExtension.Critical)
				{
					throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"KeyUsage\" marcata critica.");
				}
				break;
			}
			case "2.5.29.37":
				flag3 = true;
				try
				{
					int num2 = ASN1DERHelper.SequenceFirstTagPosition(current.RawData, 0);
					if (!ASN1DERHelper.IsOID("1.3.6.1.5.5.7.3.8", current.RawData, num2))
					{
						throw new Exception();
					}
					if (ASN1DERHelper.NextTagPosition(current.RawData, num2) != -1)
					{
						throw new Exception();
					}
				}
				catch
				{
					throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"extendedKeyUsage\" correttamente valorizzata; deve contenere esclusivamente il campo keyPurposeId=timeStamping.");
				}
				if (!current.Critical)
				{
					throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"authorityKeyIdentifier\" marcata critica.");
				}
				break;
			case "2.5.29.32":
				flag2 = true;
				if (!Regex.IsMatch(current.Format(multiLine: false), "=([0-9]+\\.?)+.+=CPS.+(http|ftp)s?://", RegexOptions.IgnoreCase))
				{
					throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"certificatePolicies\" correttamente valorizzata; deve contenere l'OID della Certificate Policy e l'URL che punta al Certificate Practice Statement (CPS).");
				}
				if (current.Critical)
				{
					throw new CryptographicException("Il certificato della marca temporale ha erroneamente l'estensione \"certificatePolicies\" marcata critica.");
				}
				break;
			case "2.5.29.35":
				flag4 = true;
				try
				{
					int num = ASN1DERHelper.SequenceFirstTagPosition(current.RawData, 0);
					if (current.RawData[num] != 128)
					{
						throw new Exception();
					}
					if (ASN1DERHelper.TagValueLenght(current.RawData, num) == 0)
					{
						throw new Exception();
					}
				}
				catch
				{
					throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"authorityKeyIdentifier\" correttamente valorizzata; deve contenere almeno il campo keyIdentifier.");
				}
				if (current.Critical)
				{
					throw new CryptographicException("Il certificato della marca temporale ha erroneamente l'estensione \"authorityKeyIdentifier\" marcata critica.");
				}
				break;
			case "2.5.29.14":
				flag5 = true;
				if (string.IsNullOrEmpty(current.Format(multiLine: false)))
				{
					throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"subjectKeyIdentifier\" correttamente valorizzata; deve contenere il keyIdentifier.");
				}
				if (current.Critical)
				{
					throw new CryptographicException("Il certificato della marca temporale ha erroneamente l'estensione \"subjectKeyIdentifier\" marcata critica.");
				}
				break;
			default:
				if (current.Critical)
				{
					throw new CryptographicException("Il certificato della marca temporale ha erroneamente l'estensione \"" + current.Oid.FriendlyName + "\" (" + current.Oid.Value + ") marcata critica.");
				}
				break;
			}
		}
		if (!flag)
		{
			throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"KeyUsage\".");
		}
		if (!flag2)
		{
			throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"certificatePolicies\".");
		}
		if (!flag3)
		{
			throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"crlDistributionPoints\".");
		}
		if (!flag4)
		{
			throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"authorityKeyIdentifier\".");
		}
		if (!flag5)
		{
			throw new CryptographicException("Il certificato della marca temporale non ha l'estensione \"subjectKeyIdentifier\".");
		}
	}

	private static X509Certificate2Collection updateCNIPACertificateStore(string cnipaFilePath)
	{
		X509Certificate2Collection x509Certificate2Collection = new X509Certificate2Collection();
		X509Store x509Store = new X509Store(StoreName.Root, StoreLocation.CurrentUser);
		x509Store.Open(OpenFlags.ReadWrite);
		try
		{
			x509Certificate2Collection = loadCNIPACertificates(cnipaFilePath);
			x509Store.AddRange(x509Certificate2Collection);
			return x509Certificate2Collection;
		}
		finally
		{
			x509Store.Close();
		}
	}

	private static X509Certificate2Collection loadCNIPACertificates(string cnipaFilePath)
	{
		X509Certificate2Collection x509Certificate2Collection = new X509Certificate2Collection();
		try
		{
			SignedCms signedCms = new SignedCms();
			signedCms.Decode(File.ReadAllBytes(cnipaFilePath));
			signedCms.CheckSignature(verifySignatureOnly: true);
			X509Certificate2 x509Certificate = new X509Certificate2();
			x509Certificate.Import(Resources.UfficioSicurezzaDigitPA);
			if (!signedCms.SignerInfos[0].Certificate.Thumbprint.Equals(x509Certificate.Thumbprint))
			{
				throw new Exception("Firma effettuata con un certificato non previsto.");
			}
			foreach (ZipEntry item in ZipFile.Read((Stream)new MemoryStream(signedCms.ContentInfo.Content)).SelectEntries("name = *.cer OR name = *.crt OR name = *.der OR name = *.b64"))
			{
				MemoryStream memoryStream = new MemoryStream();
				item.Extract((Stream)memoryStream);
				x509Certificate2Collection.Import(memoryStream.ToArray());
			}
			return x509Certificate2Collection;
		}
		catch (Exception innerException)
		{
			throw new Exception("File di lista dei certifica del CNIPA non valido.", innerException);
		}
	}

	public static void UpdateCNIPACertificates(string cnipaFilePath)
	{
		updateCNIPACertificateStore(cnipaFilePath);
	}

	public static string UpdateCNIPAFile(string cnipaDownloadPage, string cnipaFilePath)
	{
		Uri uri = new Uri(cnipaDownloadPage);
		WebClient webClient = new WebClient
		{
			Proxy = WebRequest.DefaultWebProxy
		};
		webClient.Proxy.Credentials = CredentialCache.DefaultCredentials;
		webClient.Credentials = CredentialCache.DefaultCredentials;
		Match match = Regex.Match(webClient.DownloadString(uri), "href=\"(.+)\"", RegexOptions.IgnoreCase);
		if (!match.Success)
		{
			throw new Exception("Non è presente il link al file della lista dei certificati nella pagina del CNIPA all'url specificato.");
		}
		Uri uri2 = new Uri(match.Groups[1].ToString());
		if (!uri2.IsAbsoluteUri)
		{
			uri2 = new Uri(uri, uri2);
		}
		string text = uri2.AbsolutePath.Substring(uri2.AbsolutePath.LastIndexOf("/") + 1);
		if (!File.Exists(cnipaFilePath) || !text.Equals(Path.GetFileName(cnipaFilePath)))
		{
			string text2 = ((Path.GetDirectoryName(cnipaFilePath) != "") ? Path.GetDirectoryName(cnipaFilePath) : ".") + "\\" + text;
			webClient.DownloadFile(uri2, text2);
			if (!IsMoreThanVista)
			{
				updateCNIPACertificateStore(text2);
			}
			else
			{
				loadCNIPACertificates(text2);
			}
			if (File.Exists(cnipaFilePath))
			{
				File.Delete(cnipaFilePath);
			}
			return text2;
		}
		return cnipaFilePath;
	}
}
