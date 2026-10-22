using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Security.Cryptography.Pkcs;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Windows.Forms;

namespace WKISigner;

public static class CadesSigner
{
	private static class ASN1
	{
		public const byte SEQUENCE_DER = 48;

		public const byte OCTET_STRING_DER = 4;
	}

	public static string ChooseCertificate()
	{
		return ChooseCertificate(IntPtr.Zero);
	}

	public static string ChooseCertificate(IntPtr hWndParent)
	{
		bool noValidCertificateFound;
		return ChooseCertificate(out noValidCertificateFound, hWndParent);
	}

	public static string ChooseCertificate(out bool noValidCertificateFound)
	{
		return ChooseCertificate(out noValidCertificateFound, IntPtr.Zero);
	}

	public static string ChooseCertificate(out bool noValidCertificateFound, IntPtr hWndParent)
	{
		return CertHelper.ChooseCertificate(out noValidCertificateFound, hWndParent)?.Thumbprint;
	}

	public static CmsSigner BuildCmsSigner()
	{
		bool noValidCertificateFound;
		return BuildCmsSigner(out noValidCertificateFound);
	}

	public static CmsSigner BuildCmsSigner(IntPtr hWndParent)
	{
		bool noValidCertificateFound;
		return BuildCmsSigner(out noValidCertificateFound, hWndParent);
	}

	public static CmsSigner BuildCmsSigner(out bool noValidCertificateFound)
	{
		return BuildCmsSigner(out noValidCertificateFound, IntPtr.Zero);
	}

	public static CmsSigner BuildCmsSigner(out bool noValidCertificateFound, IntPtr hWndParent)
	{
		X509Certificate2 x509Certificate;
		while (true)
		{
			x509Certificate = CertHelper.ChooseCertificate(out noValidCertificateFound, hWndParent);
			if (x509Certificate == null)
			{
				return null;
			}
			if (CertHelper.IsHardwareCertificate(x509Certificate))
			{
				break;
			}
			MessageBox.Show("Non è possibile effettuare la firma elettronica con un certificato non proveniente da un dispositivo hardware.");
		}
		CmsSigner cmsSigner = new CmsSigner(SubjectIdentifierType.IssuerAndSerialNumber, x509Certificate)
		{
			IncludeOption = X509IncludeOption.EndCertOnly,
			DigestAlgorithm = new Oid("2.16.840.1.101.3.4.2.1")
		};
		cmsSigner.SignedAttributes.Add(new Pkcs9SigningTime());
		Oid oid = new Oid("1.2.840.113549.1.9.16.2.47");
		byte[] array = new SHA256Managed().ComputeHash(cmsSigner.Certificate.RawData);
		List<byte> list = new List<byte>();
		byte[] obj = new byte[8] { 48, 0, 48, 0, 48, 0, 4, 0 };
		obj[1] = BitConverter.GetBytes(array.Length + 6)[0];
		obj[3] = BitConverter.GetBytes(array.Length + 4)[0];
		obj[5] = BitConverter.GetBytes(array.Length + 2)[0];
		obj[7] = BitConverter.GetBytes(array.Length)[0];
		list.AddRange(obj);
		list.AddRange(array);
		AsnEncodedData asnEncodedData = new AsnEncodedData(oid, list.ToArray());
		cmsSigner.SignedAttributes.Add(asnEncodedData);
		return cmsSigner;
	}

	public static byte[] Sign(byte[] content, string thumbprint)
	{
		X509Store x509Store = new X509Store(StoreName.My, StoreLocation.CurrentUser);
		x509Store.Open(OpenFlags.ReadOnly);
		X509Certificate2 x509Certificate = null;
		if (!string.IsNullOrEmpty(thumbprint))
		{
			X509Certificate2Collection x509Certificate2Collection = x509Store.Certificates.Find(X509FindType.FindByThumbprint, thumbprint, validOnly: false);
			if (x509Certificate2Collection.Count > 0)
			{
				x509Certificate = x509Certificate2Collection[0];
			}
		}
		if (x509Certificate == null)
		{
			throw new Exception("Certificato non trovato.");
		}
		CmsSigner cmsSigner = new CmsSigner(SubjectIdentifierType.IssuerAndSerialNumber, x509Certificate);
		if (!CertHelper.IsHardwareCertificate(x509Certificate))
		{
			throw new Exception("Non è possibile effettuare la firma elettronica con un certificato non proveniente da un dispositivo hardware.");
		}
		cmsSigner.IncludeOption = X509IncludeOption.EndCertOnly;
		cmsSigner.DigestAlgorithm = new Oid("2.16.840.1.101.3.4.2.1");
		cmsSigner.SignedAttributes.Add(new Pkcs9SigningTime());
		Oid oid = new Oid("1.2.840.113549.1.9.16.2.47");
		byte[] array = new SHA256Managed().ComputeHash(x509Certificate.RawData);
		List<byte> list = new List<byte>();
		byte[] obj = new byte[8] { 48, 0, 48, 0, 48, 0, 4, 0 };
		obj[1] = BitConverter.GetBytes(array.Length + 6)[0];
		obj[3] = BitConverter.GetBytes(array.Length + 4)[0];
		obj[5] = BitConverter.GetBytes(array.Length + 2)[0];
		obj[7] = BitConverter.GetBytes(array.Length)[0];
		list.AddRange(obj);
		list.AddRange(array);
		AsnEncodedData asnEncodedData = new AsnEncodedData(oid, list.ToArray());
		cmsSigner.SignedAttributes.Add(asnEncodedData);
		return Sign(content, cmsSigner);
	}

	public static byte[] Sign(string filePath, string thumbprint)
	{
		return Sign(File.ReadAllBytes(filePath), thumbprint);
	}

	public static byte[] Sign(byte[] content, CmsSigner cmsSigner)
	{
		Action<string> action = delegate
		{
		};
		if (CertHelper.LogEnabled)
		{
			action = delegate(string s)
			{
				File.AppendAllText(".\\WKISigner.log", DateTime.Now.ToString() + " " + s + "\r\n");
			};
		}
		SignedCms signedCms;
		if (SignedFileInfo.Load(content).ContentType == SignedFileInfo.ContentTypes.SignedData)
		{
			signedCms = new SignedCms(SubjectIdentifierType.IssuerAndSerialNumber);
			signedCms.Decode(content);
		}
		else
		{
			signedCms = new SignedCms(SubjectIdentifierType.IssuerAndSerialNumber, new ContentInfo(content), detached: false);
		}
		try
		{
			signedCms.ComputeSignature(cmsSigner, silent: false);
		}
		catch (CryptographicException ex)
		{
			if (CertHelper.LogEnabled)
			{
				StringBuilder stringBuilder = new StringBuilder();
				for (Exception ex2 = ex; ex2 != null; ex2 = ex2.InnerException)
				{
					stringBuilder.AppendLine($"{ex2.GetType()}: {ex.Message}");
				}
				action("Errore nella funzione di Sign:");
				action(stringBuilder.ToString());
			}
			return null;
		}
		return signedCms.Encode();
	}

	public static byte[] Sign(string filePath, CmsSigner cmsSigner)
	{
		return Sign(File.ReadAllBytes(filePath), cmsSigner);
	}

	public static void Verify(byte[] content, CertHelper.CLRVerification clrMode, DateTime verificationTime, string cnipaFilePath)
	{
		try
		{
			SignedCms signedCms = new SignedCms();
			signedCms.Decode(content);
			signedCms.CheckSignature(verifySignatureOnly: true);
			int num = 0;
			SignerInfoEnumerator enumerator = signedCms.SignerInfos.GetEnumerator();
			while (enumerator.MoveNext())
			{
				SignerInfo current = enumerator.Current;
				num++;
				try
				{
					if (current.DigestAlgorithm.Value != "2.16.840.1.101.3.4.2.1")
					{
						throw new CryptographicException("Digest algorithm non sha256.");
					}
					bool flag = false;
					bool flag2 = false;
					CryptographicAttributeObjectEnumerator enumerator2 = current.SignedAttributes.GetEnumerator();
					while (enumerator2.MoveNext())
					{
						CryptographicAttributeObject current2 = enumerator2.Current;
						string value = current2.Oid.Value;
						if (!(value == "1.2.840.113549.1.9.5"))
						{
							if (value == "1.2.840.113549.1.9.16.2.47")
							{
								flag2 = true;
								if (current2.Values.Count != 1)
								{
									throw new CryptographicException("Attributo SigningCertificateV2 malformato.");
								}
								byte[] rawData = current2.Values[0].RawData;
								byte[] data;
								try
								{
									int tagPosition = ASN1DERHelper.SequenceFirstTagPosition(rawData, ASN1DERHelper.SequenceFirstTagPosition(rawData, ASN1DERHelper.SequenceFirstTagPosition(rawData, 0)));
									data = ASN1DERHelper.TagValue(rawData, tagPosition);
								}
								catch (Exception inner)
								{
									throw new CryptographicException("Attributo SigningCertificateV2 malformato.", inner);
								}
								byte[] data2 = new SHA256Managed().ComputeHash(current.Certificate.RawData);
								if (!ASN1DERHelper.Equals(data, data2))
								{
									throw new CryptographicException("Attributo SigningCertificateV2 non corrispondente al certificato utilizzato per la firma.");
								}
							}
						}
						else
						{
							flag = true;
							if (current2.Values.Count != 1 || !(current2.Values[0] is Pkcs9SigningTime))
							{
								throw new CryptographicException("Attributo SigningTime malformato.");
							}
						}
					}
					if (!flag)
					{
						throw new CryptographicException("Attributo SigningTime non presente.");
					}
					if (!flag2)
					{
						throw new CryptographicException("Attributo SigningCertificateV2 non presente.");
					}
					CertHelper.IsSignerCertificate(current.Certificate);
					CertHelper.VerifyCertificate(current.Certificate, clrMode.Equals(CertHelper.CLRVerification.OnLine) ? X509RevocationMode.Online : X509RevocationMode.NoCheck, verificationTime, cnipaFilePath);
					enumerator2 = current.UnsignedAttributes.GetEnumerator();
					while (enumerator2.MoveNext())
					{
						CryptographicAttributeObject current3 = enumerator2.Current;
						if (current3.Oid.Value != "1.2.840.113549.1.9.16.2.14")
						{
							continue;
						}
						try
						{
							if (current3.Values.Count != 1)
							{
								throw new CryptographicException();
							}
							int num2 = ASN1DERHelper.ContextSpecificFirstTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, 0)), 0);
							if (num2 == -1)
							{
								throw new Exception("CMS senza contenuto.");
							}
							num2 = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, num2))));
							if (ASN1DERHelper.ContextSpecificFirstTagPosition(content, num2, 0) != -1)
							{
								num2 = ASN1DERHelper.NextTagPosition(content, num2);
							}
							if (ASN1DERHelper.ContextSpecificFirstTagPosition(content, num2, 1) != -1)
							{
								num2 = ASN1DERHelper.NextTagPosition(content, num2);
							}
							num2 = ASN1DERHelper.SetFirstTagPosition(content, num2);
							for (int i = 1; i < num; i++)
							{
								num2 = ASN1DERHelper.NextTagPosition(content, num2);
							}
							num2 = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, num2))));
							if (ASN1DERHelper.ContextSpecificFirstTagPosition(content, num2, 0) != -1)
							{
								num2 = ASN1DERHelper.NextTagPosition(content, num2);
							}
							int num3 = ASN1DERHelper.NextTagPosition(content, num2);
							if (content[num3] != 4)
							{
								throw new Exception("Atteso un SignatureValue alla posizione: " + num3 + " del CMS.");
							}
							TimeStamper.VerifyTimeStamp(ASN1DERHelper.TagValue(content, num3), current3.Values[0].RawData, clrMode, verificationTime, cnipaFilePath);
						}
						catch (Exception inner2)
						{
							throw new CryptographicException("Attributo della marca temporale mal formato.", inner2);
						}
					}
				}
				catch (CryptographicException inner3)
				{
					throw new CryptographicException("Verifica non riuscita per la firma N." + num + ".", inner3);
				}
			}
		}
		catch (CryptographicException e)
		{
			throw new VerificationFailedException("Verifica fallita.", e);
		}
	}

	public static void Verify(string filePath, CertHelper.CLRVerification clrMode, DateTime verificationTime, string cnipaFilePath)
	{
		Verify(File.ReadAllBytes(filePath), clrMode, verificationTime, cnipaFilePath);
	}

	public static byte[] ExtractContent(byte[] content)
	{
		SignedCms signedCms = new SignedCms();
		signedCms.Decode(content);
		if (signedCms.Detached)
		{
			throw new ArgumentException("Non è possibile estrarre il contenuto da un file di firma.");
		}
		return signedCms.ContentInfo.Content;
	}

	public static byte[] ExtractContent(string filePath)
	{
		return ExtractContent(File.ReadAllBytes(filePath));
	}

	public static byte[] ExtractCertificate(byte[] content, int signerNumber = 1)
	{
		SignedCms signedCms = new SignedCms();
		signedCms.Decode(content);
		if (signerNumber < 1 || signerNumber > signedCms.SignerInfos.Count)
		{
			throw new ArgumentOutOfRangeException("signerNumber", "Non presente.");
		}
		return signedCms.SignerInfos[signerNumber - 1].Certificate.Export(X509ContentType.Cert);
	}

	public static byte[] ExtractCertificate(string filePath, int signerNumber = 1)
	{
		return ExtractCertificate(File.ReadAllBytes(filePath), signerNumber);
	}

	public static byte[] SignerTimeStamp(byte[] content, int signerNumber, string serverURL, string userName, string passWord)
	{
		SignedCms signedCms = new SignedCms();
		signedCms.Decode(content);
		signedCms.CheckSignature(verifySignatureOnly: true);
		if (signerNumber < 1 || signerNumber > signedCms.SignerInfos.Count)
		{
			throw new ArgumentOutOfRangeException("signerNumber", "Non valido.");
		}
		CryptographicAttributeObjectEnumerator enumerator = signedCms.SignerInfos[signerNumber - 1].UnsignedAttributes.GetEnumerator();
		while (enumerator.MoveNext())
		{
			if (enumerator.Current.Oid.Value == "1.2.840.113549.1.9.16.2.14")
			{
				throw new ArgumentException("Firma già marcata temporalmente.", "signerNumber");
			}
		}
		int num = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, 0));
		int num2 = ASN1DERHelper.ContextSpecificFirstTagPosition(content, num, 0);
		if (num2 == -1)
		{
			throw new ArgumentException("CMS senza contenuto.", "content");
		}
		int num3 = num2;
		num2 = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, num3))));
		if (ASN1DERHelper.ContextSpecificFirstTagPosition(content, num2, 0) != -1)
		{
			num2 = ASN1DERHelper.NextTagPosition(content, num2);
		}
		if (ASN1DERHelper.ContextSpecificFirstTagPosition(content, num2, 1) != -1)
		{
			num2 = ASN1DERHelper.NextTagPosition(content, num2);
		}
		int num4 = num2;
		int num5 = ASN1DERHelper.SetFirstTagPosition(content, num4);
		for (int i = 1; i < signerNumber; i++)
		{
			num5 = ASN1DERHelper.NextTagPosition(content, num5);
		}
		num2 = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, num5))));
		if (ASN1DERHelper.ContextSpecificFirstTagPosition(content, num2, 0) != -1)
		{
			num2 = ASN1DERHelper.NextTagPosition(content, num2);
		}
		int num6 = ASN1DERHelper.NextTagPosition(content, num2);
		if (content[num6] != 4)
		{
			throw new ArgumentException("Atteso un SignatureValue alla posizione: " + num6 + ".", "content");
		}
		byte[] timeStamp = TimeStamper.GetTimeStamp(ASN1DERHelper.TagValue(content, num6), serverURL, userName, passWord);
		int num7 = ASN1DERHelper.NextTagPosition(content, num6);
		using MemoryStream memoryStream = new MemoryStream();
		byte[] array = ASN1DERHelper.DerValueLength(timeStamp.Length);
		byte[] array2 = CryptoConfig.EncodeOID("1.2.840.113549.1.9.16.2.14");
		int num8 = array2.Length + 1 + array.Length + timeStamp.Length;
		byte[] array3 = ASN1DERHelper.DerValueLength(num8);
		num8 += 1 + array3.Length;
		byte[] array4 = new byte[1] { 128 };
		if (num7 == -1 || ASN1DERHelper.ContextSpecificFirstTagPosition(content, num7, 1) == -1)
		{
			array4 = ASN1DERHelper.DerValueLength(num8);
			num8 += 1 + array4.Length;
		}
		else if (content[num7 + 1] != 128)
		{
			array4 = ASN1DERHelper.DerValueLength(ASN1DERHelper.TagValueLenght(content, num7) + num8);
			num8 += array4.Length - ASN1DERHelper.TagValueLenghtBytesCount(content, num7);
		}
		byte[] array5 = new byte[1] { 128 };
		if (content[num5 + 1] != 128)
		{
			array5 = ASN1DERHelper.DerValueLength(ASN1DERHelper.TagValueLenght(content, num5) + num8);
			num8 += array5.Length - ASN1DERHelper.TagValueLenghtBytesCount(content, num5);
		}
		byte[] array6 = new byte[1] { 128 };
		if (content[num4 + 1] != 128)
		{
			array6 = ASN1DERHelper.DerValueLength(ASN1DERHelper.TagValueLenght(content, num4) + num8);
			num8 += array6.Length - ASN1DERHelper.TagValueLenghtBytesCount(content, num4);
		}
		byte[] array7 = new byte[1] { 128 };
		if (content[num3 + 1] != 128)
		{
			array7 = ASN1DERHelper.DerValueLength(ASN1DERHelper.TagValueLenght(content, num3) + num8);
			num8 += array7.Length - ASN1DERHelper.TagValueLenghtBytesCount(content, num3);
		}
		byte[] array8 = new byte[1] { 128 };
		if (content[num + 1] != 128)
		{
			array8 = ASN1DERHelper.DerValueLength(ASN1DERHelper.TagValueLenght(content, num) + num8);
			num8 += array8.Length - ASN1DERHelper.TagValueLenghtBytesCount(content, num);
		}
		byte[] array9 = new byte[1] { 128 };
		if (content[num + 1] != 128)
		{
			array9 = ASN1DERHelper.DerValueLength(ASN1DERHelper.TagValueLenght(content, 0) + num8);
		}
		memoryStream.WriteByte(48);
		memoryStream.Write(array9, 0, array9.Length);
		memoryStream.Write(content, ASN1DERHelper.TagValueStartPosition(content, 0), num - ASN1DERHelper.TagValueStartPosition(content, 0));
		memoryStream.WriteByte(160);
		memoryStream.Write(array8, 0, array8.Length);
		memoryStream.WriteByte(48);
		memoryStream.Write(array7, 0, array7.Length);
		memoryStream.Write(content, ASN1DERHelper.TagValueStartPosition(content, num3), num4 - ASN1DERHelper.TagValueStartPosition(content, num3));
		memoryStream.WriteByte(49);
		memoryStream.Write(array6, 0, array6.Length);
		memoryStream.Write(content, ASN1DERHelper.TagValueStartPosition(content, num4), num5 - ASN1DERHelper.TagValueStartPosition(content, num4));
		memoryStream.WriteByte(48);
		memoryStream.Write(array5, 0, array5.Length);
		memoryStream.Write(content, ASN1DERHelper.TagValueStartPosition(content, num5), (num7 != -1) ? (num7 - ASN1DERHelper.TagValueStartPosition(content, num5)) : ASN1DERHelper.TagValue(content, num5).Length);
		memoryStream.WriteByte(161);
		memoryStream.Write(array4, 0, array4.Length);
		if (num7 != -1 && ASN1DERHelper.ContextSpecificFirstTagPosition(content, num7, 1) != -1)
		{
			byte[] array10 = ASN1DERHelper.TagValue(content, num7);
			memoryStream.Write(array10, 0, array10.Length);
		}
		memoryStream.WriteByte(48);
		memoryStream.Write(array3, 0, array3.Length);
		memoryStream.Write(array2, 0, array2.Length);
		memoryStream.WriteByte(49);
		memoryStream.Write(array, 0, array.Length);
		memoryStream.Write(timeStamp, 0, timeStamp.Length);
		int num9 = num5 + ASN1DERHelper.TagLength(content, num5);
		int num10 = content.Length - num9;
		if (num10 > 0)
		{
			memoryStream.Write(content, num9, num10);
		}
		return memoryStream.ToArray();
	}

	public static byte[] SignerTimeStamp(string filePath, int signerNumber, string serverURL, string userName, string passWord)
	{
		return SignerTimeStamp(File.ReadAllBytes(filePath), signerNumber, serverURL, userName, passWord);
	}

	public static byte[] ExtractSignerTimeStamp(byte[] content, int signerNumber = 1)
	{
		SignedCms signedCms = new SignedCms();
		signedCms.Decode(content);
		if (signerNumber < 1 || signerNumber > signedCms.SignerInfos.Count)
		{
			throw new ArgumentOutOfRangeException("signerNumber", "Non presente.");
		}
		CryptographicAttributeObjectEnumerator enumerator = signedCms.SignerInfos[signerNumber - 1].UnsignedAttributes.GetEnumerator();
		while (enumerator.MoveNext())
		{
			CryptographicAttributeObject current = enumerator.Current;
			if (current.Oid.Value == "1.2.840.113549.1.9.16.2.14")
			{
				return current.Values[0].RawData;
			}
		}
		throw new Exception("La firma n." + signerNumber + " non è marcata temporalmente.");
	}

	public static byte[] ExtractSignerTimeStamp(string filePath, int signerNumber = 1)
	{
		return ExtractSignerTimeStamp(File.ReadAllBytes(filePath));
	}
}
