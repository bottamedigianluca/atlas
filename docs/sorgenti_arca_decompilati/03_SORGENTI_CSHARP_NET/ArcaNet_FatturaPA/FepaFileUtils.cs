using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Linq;
using ArcaNet.ARKManager_V4;

namespace ArcaNet.FatturaPA4Vfp;

public static class FepaFileUtils
{
	internal static byte[] a(byte[] A_0)
	{
		IEnumerable<byte> source = A_0.Take(10);
		int num = -1;
		if (source.Take(3).SequenceEqual(new byte[3] { 239, 187, 191 }))
		{
			num = 3;
		}
		else if (source.Take(2).SequenceEqual(new byte[2] { 254, 255 }))
		{
			num = 2;
		}
		else if (source.Take(2).SequenceEqual(new byte[2] { 255, 254 }))
		{
			num = 2;
		}
		else if (source.Take(4).SequenceEqual(new byte[4] { 0, 0, 254, 255 }))
		{
			num = 4;
		}
		else if (source.Take(4).SequenceEqual(new byte[4] { 255, 254, 0, 0 }))
		{
			num = 4;
		}
		if (num <= 0)
		{
			return A_0;
		}
		return A_0.Skip(num).ToArray();
	}

	public static XmlDocument ReliableLoad(byte[] sourceXml)
	{
		byte[] buffer = pa.c(sourceXml);
		XmlDocument xmlDocument = new XmlDocument();
		try
		{
			using MemoryStream inStream = new MemoryStream(buffer);
			xmlDocument.Load(inStream);
		}
		catch (XmlException)
		{
			using MemoryStream inStream2 = new MemoryStream(Encoding.UTF8.GetBytes(Encoding.ASCII.GetString(sourceXml)));
			xmlDocument.Load(inStream2);
		}
		return xmlDocument;
	}

	public static byte[] SmartDecode(byte[] source, bool outputWithoutBOM = false)
	{
		source = pa.c(source);
		if (outputWithoutBOM)
		{
			source = a(source);
		}
		return source;
	}

	public static XDocument SmartDecodeToXDocument(byte[] source)
	{
		return pb.a(SmartDecodeToXmlDocument(source));
	}

	public static XmlDocument SmartDecodeToXmlDocument(byte[] source)
	{
		int a_ = 1;
		try
		{
			return ReliableLoad(source);
		}
		catch (XmlException innerException)
		{
			throw new XmlException(GetDocTypeOnLTAUserResult4Vfp.b("㙴ᙶ\u1778ᕺቼ\u0b7eꆀ\uf182\ue084\ue686\ued88ꮊ햌슎\udd90붒떔잖\ueb98\uf49aﾜﺞ쎠쾢\udca4螦쮨\ud9aa슬쒮풰\uddb2閴\ud8b6쮸鮺풼펾귀ꛂꋄꛆꗈ\uebcaꯌꃎꏐ뻒냔돖", a_), innerException);
		}
	}
}
