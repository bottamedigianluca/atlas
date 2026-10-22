using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography.Pkcs;

namespace WKISigner;

public class SignedFileInfo
{
	public enum ContentTypes
	{
		SignedData,
		TimestampedData,
		Unknown,
		NotCMS
	}

	public readonly ContentTypes ContentType;

	public readonly SignatureInfo[] Signatures = new SignatureInfo[0];

	public readonly TimestampInfo[] Timestamps = new TimestampInfo[0];

	private SignedFileInfo(byte[] content)
	{
		try
		{
			if (ASN1DERHelper.IsOID("1.2.840.113549.1.7.2", content, ASN1DERHelper.SequenceFirstTagPosition(content, 0)))
			{
				ContentType = ContentTypes.SignedData;
				SignedCms signedCms = new SignedCms();
				signedCms.Decode(content);
				Signatures = new SignatureInfo[signedCms.SignerInfos.Count];
				int num = 0;
				SignerInfoEnumerator enumerator = signedCms.SignerInfos.GetEnumerator();
				while (enumerator.MoveNext())
				{
					SignerInfo current = enumerator.Current;
					Signatures[num] = new SignatureInfo(current);
					num++;
				}
			}
			else if (ASN1DERHelper.IsOID("1.2.840.113549.1.9.16.1.31", content, ASN1DERHelper.SequenceFirstTagPosition(content, 0)))
			{
				ContentType = ContentTypes.TimestampedData;
				List<TimestampInfo> list = new List<TimestampInfo>();
				bool flag = false;
				while (!flag)
				{
					try
					{
						list.Add(new TimestampInfo(TimeStamper.ExtractTimeStamp(content, list.Count + 1)));
					}
					catch (ArgumentException)
					{
						flag = true;
					}
				}
				Timestamps = list.ToArray();
				byte[] array = TimeStamper.ExtractContent(content);
				bool flag2;
				try
				{
					flag2 = ASN1DERHelper.IsOID("1.2.840.113549.1.7.2", array, ASN1DERHelper.SequenceFirstTagPosition(array, 0));
				}
				catch (ASN1DERException)
				{
					flag2 = false;
				}
				if (flag2)
				{
					SignedCms signedCms2 = new SignedCms();
					signedCms2.Decode(array);
					Signatures = new SignatureInfo[signedCms2.SignerInfos.Count];
					int num2 = 0;
					SignerInfoEnumerator enumerator = signedCms2.SignerInfos.GetEnumerator();
					while (enumerator.MoveNext())
					{
						SignerInfo current2 = enumerator.Current;
						Signatures[num2] = new SignatureInfo(current2);
						num2++;
					}
				}
			}
			else
			{
				ContentType = ContentTypes.Unknown;
			}
		}
		catch (ASN1DERException)
		{
			ContentType = ContentTypes.NotCMS;
		}
	}

	public static SignedFileInfo Load(byte[] content)
	{
		return new SignedFileInfo(content);
	}

	public static SignedFileInfo Load(string filePath)
	{
		return new SignedFileInfo(File.ReadAllBytes(filePath));
	}

	public bool IsAlreadySignedBy(string certificateThumbprint)
	{
		SignatureInfo[] signatures = Signatures;
		for (int i = 0; i < signatures.Length; i++)
		{
			if (signatures[i].CertificateThumbprint.Equals(certificateThumbprint))
			{
				return true;
			}
		}
		return false;
	}
}
