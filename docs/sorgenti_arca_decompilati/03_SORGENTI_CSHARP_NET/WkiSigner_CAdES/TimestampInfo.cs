using System;
using System.Globalization;
using System.Security.Cryptography.Pkcs;
using System.Text;

namespace WKISigner;

public class TimestampInfo
{
	public readonly string DigestAlgorithm;

	public readonly string SubjectName;

	public readonly string IssuerName;

	public readonly DateTime NotBefore;

	public readonly DateTime NotAfter;

	public readonly string SerialNumber;

	public readonly DateTime GeneralizedTime;

	internal TimestampInfo(byte[] data)
	{
		SignedCms signedCms = new SignedCms();
		signedCms.Decode(data);
		DigestAlgorithm = signedCms.SignerInfos[0].DigestAlgorithm.FriendlyName;
		SubjectName = signedCms.SignerInfos[0].Certificate.SubjectName.Name;
		IssuerName = signedCms.SignerInfos[0].Certificate.IssuerName.Name;
		NotBefore = signedCms.SignerInfos[0].Certificate.NotBefore;
		NotAfter = signedCms.SignerInfos[0].Certificate.NotAfter;
		byte[] content = signedCms.ContentInfo.Content;
		int num = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, 0))));
		SerialNumber = BitConverter.ToString(ASN1DERHelper.TagValue(content, num));
		int tagPosition = ASN1DERHelper.NextTagPosition(content, num);
		GeneralizedTime = DateTime.ParseExact(Encoding.ASCII.GetString(ASN1DERHelper.TagValue(content, tagPosition)), "yyyyMMddHHmmss\\Z", CultureInfo.InvariantCulture);
	}
}
