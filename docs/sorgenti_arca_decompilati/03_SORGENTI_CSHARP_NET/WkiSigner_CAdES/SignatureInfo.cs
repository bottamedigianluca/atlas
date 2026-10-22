using System;
using System.Security.Cryptography;
using System.Security.Cryptography.Pkcs;

namespace WKISigner;

public class SignatureInfo
{
	public readonly string CertificateThumbprint;

	public readonly string DigestAlgorithm;

	public readonly string SubjectName;

	public readonly string IssuerName;

	public readonly DateTime NotBefore;

	public readonly DateTime NotAfter;

	public readonly DateTime SigningTime;

	public readonly TimestampInfo TimeStamp;

	internal SignatureInfo(SignerInfo signer)
	{
		CertificateThumbprint = signer.Certificate.Thumbprint;
		DigestAlgorithm = signer.DigestAlgorithm.FriendlyName;
		SubjectName = signer.Certificate.SubjectName.Name;
		IssuerName = signer.Certificate.IssuerName.Name;
		NotBefore = signer.Certificate.NotBefore;
		NotAfter = signer.Certificate.NotAfter;
		CryptographicAttributeObjectEnumerator enumerator = signer.SignedAttributes.GetEnumerator();
		while (enumerator.MoveNext())
		{
			if (enumerator.Current.Values[0] is Pkcs9SigningTime pkcs9SigningTime)
			{
				SigningTime = pkcs9SigningTime.SigningTime;
			}
		}
		enumerator = signer.UnsignedAttributes.GetEnumerator();
		while (enumerator.MoveNext())
		{
			CryptographicAttributeObject current = enumerator.Current;
			if (current.Oid.Value == "1.2.840.113549.1.9.16.2.14")
			{
				TimeStamp = new TimestampInfo(current.Values[0].RawData);
			}
		}
	}
}
