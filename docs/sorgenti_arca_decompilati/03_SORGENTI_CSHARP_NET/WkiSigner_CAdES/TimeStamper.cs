using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Security.Cryptography.Pkcs;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.RegularExpressions;

namespace WKISigner;

public static class TimeStamper
{
	internal static byte[] GetTimeStamp(byte[] content, string serverURL, string userName, string passWord)
	{
		if (content == null || content.Length == 0)
		{
			throw new ArgumentException("Contenuto da marcare temporalmente vuoto o non specificato.", "content");
		}
		byte[] array = CryptoConfig.EncodeOID("2.16.840.1.101.3.4.2.1");
		byte[] array2 = new SHA256Managed().ComputeHash(content);
		byte[] array3 = new byte[array2.Length + 2];
		array3[0] = 4;
		array3[1] = BitConverter.GetBytes(array2.Length)[0];
		array2.CopyTo(array3, 2);
		byte[] bytes = BitConverter.GetBytes(Math.Abs(DateTime.Now.ToBinary()));
		byte[] array4 = new byte[bytes.Length + 2];
		array4[0] = 2;
		array4[1] = BitConverter.GetBytes(bytes.Length)[0];
		bytes.CopyTo(array4, 2);
		byte[] array5;
		using (MemoryStream memoryStream = new MemoryStream())
		{
			memoryStream.WriteByte(48);
			memoryStream.WriteByte(BitConverter.GetBytes(array4.Length + array3.Length + array.Length + 9)[0]);
			memoryStream.WriteByte(2);
			memoryStream.WriteByte(1);
			memoryStream.WriteByte(1);
			memoryStream.WriteByte(48);
			memoryStream.WriteByte(BitConverter.GetBytes(array3.Length + array.Length + 4)[0]);
			memoryStream.WriteByte(48);
			memoryStream.WriteByte(BitConverter.GetBytes(array.Length + 2)[0]);
			memoryStream.Write(array, 0, array.Length);
			memoryStream.WriteByte(5);
			memoryStream.WriteByte(0);
			memoryStream.Write(array3, 0, array3.Length);
			memoryStream.Write(array4, 0, array4.Length);
			array5 = memoryStream.ToArray();
		}
		HttpWebRequest obj = (HttpWebRequest)WebRequest.Create(serverURL);
		obj.Proxy = WebRequest.DefaultWebProxy;
		obj.Proxy.Credentials = CredentialCache.DefaultCredentials;
		obj.Credentials = CredentialCache.DefaultCredentials;
		obj.Method = "POST";
		obj.ContentType = "application/timestamp-query";
		obj.Headers.Add("Authorization", "Basic " + Convert.ToBase64String(Encoding.ASCII.GetBytes(userName + ":" + passWord)));
		obj.ContentLength = array5.Length;
		obj.GetRequestStream().Write(array5, 0, array5.Length);
		obj.GetRequestStream().Close();
		HttpWebResponse httpWebResponse = (HttpWebResponse)obj.GetResponse();
		if (httpWebResponse == null)
		{
			throw new Exception("Non c'è risposta alla richiesta di creazione della marca temporale.");
		}
		byte[] array6 = new byte[httpWebResponse.ContentLength];
		using BufferedStream bufferedStream = new BufferedStream(httpWebResponse.GetResponseStream());
		if (bufferedStream.Read(array6, 0, Convert.ToInt32(httpWebResponse.ContentLength)) < httpWebResponse.ContentLength)
		{
			throw new Exception("Errore nella ricezione della marca temporale; risposta del server solo parzialmente ricevuta.");
		}
		try
		{
			int num = ASN1DERHelper.SequenceFirstTagPosition(array6, 0);
			int num2 = ASN1DERHelper.SequenceFirstTagPosition(array6, num);
			switch (array6[num2 + 2])
			{
			case 0:
			case 1:
			{
				int num3 = ASN1DERHelper.NextTagPosition(array6, num);
				byte[] array7 = new byte[ASN1DERHelper.TagLength(array6, num3)];
				Array.Copy(array6, num3, array7, 0, array7.Length);
				SignedCms signedCms = new SignedCms();
				signedCms.Decode(array7);
				signedCms.CheckSignature(verifySignatureOnly: true);
				if (signedCms.SignerInfos.Count > 1)
				{
					throw new CryptographicException("Il TimeStampToken non può contenere altra firma oltre a quella della TSA.");
				}
				byte[] content2 = signedCms.ContentInfo.Content;
				int num4;
				try
				{
					num4 = ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.SequenceFirstTagPosition(content2, 0)));
				}
				catch (Exception innerException)
				{
					throw new Exception("TSTInfo mal formato.", innerException);
				}
				int num5;
				try
				{
					num5 = ASN1DERHelper.SequenceFirstTagPosition(content2, ASN1DERHelper.SequenceFirstTagPosition(content2, num4));
				}
				catch (Exception innerException2)
				{
					throw new Exception("TSTInfo mal formato.", innerException2);
				}
				if (content2[num5] != 6)
				{
					throw new Exception("TSTInfo mal formato, non trovato il tag hashAlgorithm.");
				}
				for (int i = 0; i < array.Length; i++)
				{
					if (content2[num5 + i] != array[i])
					{
						throw new Exception("TSTInfo indica un hashAlgorithm differente da quello richiesto.");
					}
				}
				int num6 = ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.SequenceFirstTagPosition(content2, num4));
				if (content2[num6] != 4)
				{
					throw new Exception("TSTInfo mal formato, non trovato il tag hashedMessage.");
				}
				for (int j = 0; j < array3.Length; j++)
				{
					if (content2[num6 + j] != array3[j])
					{
						throw new Exception("TSTInfo indica un hashedMessage differente da quello inviato.");
					}
				}
				int num7 = ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.NextTagPosition(content2, num4)));
				while (num7 != -1 && content2[num7] != 2)
				{
					num7 = ASN1DERHelper.NextTagPosition(content2, num7);
				}
				if (num7 == -1)
				{
					throw new Exception("TSTInfo mal formato, Nonce incluso nella richiesta ma non nella risposta.");
				}
				for (int k = 0; k < array4.Length; k++)
				{
					if (content2[num7 + k] != array4[k])
					{
						throw new Exception("TSTInfo indica un Nonce differente da quello inviato.");
					}
				}
				return array7;
			}
			case 2:
				throw new Exception("Il valore PKIStatus è \"rejection\"");
			case 3:
				throw new Exception("Il valore PKIStatus è \"waiting\"");
			case 4:
				throw new Exception("Il valore PKIStatus è \"revocationWarning\"");
			case 5:
				throw new Exception("Il valore PKIStatus è \"revocationNotification\"");
			default:
				throw new Exception("Il valore PKIStatus non è previsto.");
			}
		}
		catch (Exception e)
		{
			throw new VerificationFailedException("Risposta del server della marca temporale negativa o mal formata.", e)
			{
				Data = 
				{
					{
						(object)"RequestContent",
						(object)array5
					},
					{
						(object)"ResponseContent",
						(object)array6
					}
				}
			};
		}
	}

	internal static void VerifyTimeStamp(byte[] content, byte[] timeStampToken, CertHelper.CLRVerification clrMode, DateTime verificationTime, string cnipaFilePath)
	{
		SignedCms signedCms = new SignedCms();
		signedCms.Decode(timeStampToken);
		signedCms.CheckSignature(verifySignatureOnly: true);
		if (signedCms.SignerInfos.Count > 1)
		{
			throw new CryptographicException("La marca temporale non può contenere altra firma oltre a quella della TSA.");
		}
		byte[] content2 = signedCms.ContentInfo.Content;
		int sequencePosition = ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.SequenceFirstTagPosition(content2, 0)));
		int oidTagPosition = ASN1DERHelper.SequenceFirstTagPosition(content2, ASN1DERHelper.SequenceFirstTagPosition(content2, sequencePosition));
		int num = ASN1DERHelper.NextTagPosition(content2, ASN1DERHelper.SequenceFirstTagPosition(content2, sequencePosition));
		if (!ASN1DERHelper.IsOID("2.16.840.1.101.3.4.2.1", content2, oidTagPosition))
		{
			throw new CryptographicException("Tag hashAlgorithm mancante od errato.");
		}
		if (content2[num] != 4)
		{
			throw new CryptographicException("Non trovato il tag hashedMessage.");
		}
		if (!ASN1DERHelper.Equals(data2: new SHA256Managed().ComputeHash(content), data1: ASN1DERHelper.TagValue(content2, num)))
		{
			throw new CryptographicException("La marca temporale non è applicabile alla firma indicata.");
		}
		CertHelper.IsTimestampCertificate(signedCms.SignerInfos[0].Certificate);
		CertHelper.VerifyCertificate(signedCms.SignerInfos[0].Certificate, clrMode.Equals(CertHelper.CLRVerification.OnLine) ? X509RevocationMode.Online : X509RevocationMode.NoCheck, verificationTime, cnipaFilePath);
	}

	public static byte[] StampData(byte[] content, string serverURL, string userName, string passWord)
	{
		try
		{
			if (ASN1DERHelper.IsOID("1.2.840.113549.1.9.16.1.31", content, ASN1DERHelper.SequenceFirstTagPosition(content, 0)))
			{
				throw new NotImplementedException("Non è implementata la doppia marcatura temporale di un file.");
			}
		}
		catch (ASN1DERException)
		{
		}
		byte[] array = CryptoConfig.EncodeOID("1.2.840.113549.1.9.16.1.31");
		byte[] array2 = ASN1DERHelper.DerValueLength(content.Length);
		byte[] timeStamp = GetTimeStamp(content, serverURL, userName, passWord);
		byte[] array3 = ASN1DERHelper.DerValueLength(timeStamp.Length);
		byte[] array4 = ASN1DERHelper.DerValueLength(1 + array3.Length + timeStamp.Length);
		byte[] array5 = ASN1DERHelper.DerValueLength(6 + array2.Length + content.Length + array4.Length + array3.Length + timeStamp.Length);
		byte[] array6 = ASN1DERHelper.DerValueLength(7 + array5.Length + array2.Length + content.Length + array4.Length + array3.Length + timeStamp.Length);
		byte[] array7 = ASN1DERHelper.DerValueLength(8 + array6.Length + array.Length + array5.Length + array2.Length + content.Length + array4.Length + array3.Length + timeStamp.Length);
		using MemoryStream memoryStream = new MemoryStream();
		memoryStream.WriteByte(48);
		memoryStream.Write(array7, 0, array7.Length);
		memoryStream.Write(array, 0, array.Length);
		memoryStream.WriteByte(160);
		memoryStream.Write(array6, 0, array6.Length);
		memoryStream.WriteByte(48);
		memoryStream.Write(array5, 0, array5.Length);
		memoryStream.WriteByte(2);
		memoryStream.WriteByte(1);
		memoryStream.WriteByte(1);
		memoryStream.WriteByte(4);
		memoryStream.Write(array2, 0, array2.Length);
		memoryStream.Write(content, 0, content.Length);
		memoryStream.WriteByte(160);
		memoryStream.Write(array4, 0, array4.Length);
		memoryStream.WriteByte(48);
		memoryStream.Write(array3, 0, array3.Length);
		memoryStream.Write(timeStamp, 0, timeStamp.Length);
		return memoryStream.ToArray();
	}

	public static byte[] StampData(string filePath, string serverURL, string userName, string passWord)
	{
		return StampData(File.ReadAllBytes(filePath), serverURL, userName, passWord);
	}

	public static byte[] ExtractContent(byte[] content)
	{
		try
		{
			if (!ASN1DERHelper.IsOID("1.2.840.113549.1.9.16.1.31", content, ASN1DERHelper.SequenceFirstTagPosition(content, 0)))
			{
				throw new ArgumentException("Il contenuto non è di tipo TimeStampData.", "content");
			}
			int num = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, 0));
			if (num == -1)
			{
				throw new CryptographicException("Attributo content del contentInfo è mancante.");
			}
			int num2 = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, ASN1DERHelper.ContextSpecificFirstTagPosition(content, num, 0)));
			if (content[num2] == 22)
			{
				num2 = ASN1DERHelper.NextTagPosition(content, num2);
			}
			if (content[num2] == 48)
			{
				num2 = ASN1DERHelper.NextTagPosition(content, num2);
			}
			if (content[num2] != 4)
			{
				throw new CryptographicException("Attributo content del TimeStampedData non presente.");
			}
			return ASN1DERHelper.TagValue(content, num2);
		}
		catch (Exception innerException)
		{
			throw new Exception("Estrazione contenuto fallita.", innerException);
		}
	}

	public static byte[] ExtractContent(string filePath)
	{
		return ExtractContent(File.ReadAllBytes(filePath));
	}

	public static byte[] ExtractTimeStamp(byte[] content, int number = 1)
	{
		if (number < 1)
		{
			throw new ArgumentException("Parametro non valido.", "number");
		}
		try
		{
			if (!ASN1DERHelper.IsOID("1.2.840.113549.1.9.16.1.31", content, ASN1DERHelper.SequenceFirstTagPosition(content, 0)))
			{
				throw new Exception("Il contenuto non è di tipo TimeStampData.");
			}
			int num = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, 0));
			if (num == -1)
			{
				throw new Exception("Attributo content del contentInfo è mancante.");
			}
			int num2 = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, ASN1DERHelper.ContextSpecificFirstTagPosition(content, num, 0)));
			if (content[num2] == 22)
			{
				num2 = ASN1DERHelper.NextTagPosition(content, num2);
			}
			if (content[num2] == 48)
			{
				num2 = ASN1DERHelper.NextTagPosition(content, num2);
			}
			if (content[num2] == 4)
			{
				num2 = ASN1DERHelper.NextTagPosition(content, num2);
			}
			num2 = ASN1DERHelper.ContextSpecificFirstTagPosition(content, num2, 0);
			if (num2 == -1)
			{
				throw new Exception("Attributo tstEvidence non presente.");
			}
			for (int i = 1; i < number; i++)
			{
				num2 = ASN1DERHelper.NextTagPosition(content, num2);
				if (num2 == -1 || content[num2] != 48)
				{
					throw new ArgumentException("Marca non presente in posizione " + i + ".", "number");
				}
			}
			num2 = ASN1DERHelper.SequenceFirstTagPosition(content, num2);
			byte[] array = new byte[ASN1DERHelper.TagLength(content, num2)];
			Array.Copy(content, num2, array, 0, array.Length);
			return array;
		}
		catch (ArgumentException ex)
		{
			throw ex;
		}
		catch (Exception innerException)
		{
			throw new Exception("Estrazione della marca temporale n." + number + " fallita.", innerException);
		}
	}

	public static byte[] ExtractTimeStamp(string filePath, int number = 1)
	{
		return ExtractTimeStamp(File.ReadAllBytes(filePath));
	}

	public static byte[] ContentDigest(byte[] content)
	{
		byte[] buffer = ExtractContent(content);
		return new SHA256Managed().ComputeHash(buffer);
	}

	public static byte[] ContentDigest(string filePath)
	{
		return ContentDigest(File.ReadAllBytes(filePath));
	}

	public static void Verify(byte[] content, CertHelper.CLRVerification clrMode, DateTime verificationTime, string cnipaFilePath)
	{
		try
		{
			if (!ASN1DERHelper.IsOID("1.2.840.113549.1.9.16.1.31", content, ASN1DERHelper.SequenceFirstTagPosition(content, 0)))
			{
				throw new CryptographicException("Il contenuto non è di tipo TimeStampData.");
			}
			int num = ASN1DERHelper.NextTagPosition(content, ASN1DERHelper.SequenceFirstTagPosition(content, 0));
			if (num == -1)
			{
				throw new CryptographicException("Attributo content del contentInfo è mancante.");
			}
			int num2 = ASN1DERHelper.SequenceFirstTagPosition(content, ASN1DERHelper.ContextSpecificFirstTagPosition(content, num, 0));
			if (!ASN1DERHelper.Equals(ASN1DERHelper.TagValue(content, num2), new byte[1] { 1 }))
			{
				throw new CryptographicException("Versione del TimeStamData non supportata.");
			}
			int num3 = ASN1DERHelper.NextTagPosition(content, num2);
			if (content[num3] == 22)
			{
				num3 = ASN1DERHelper.NextTagPosition(content, num3);
			}
			List<byte> list = new List<byte>();
			if (content[num3] == 48)
			{
				if (content[ASN1DERHelper.SequenceFirstTagPosition(content, num3)] == 1 && content[ASN1DERHelper.SequenceFirstTagPosition(content, num3) + 2] != 0)
				{
					list.AddRange(ASN1DERHelper.TagValue(content, num3));
				}
				num3 = ASN1DERHelper.NextTagPosition(content, num3);
			}
			if (content[num3] == 4)
			{
				list.AddRange(ASN1DERHelper.TagValue(content, num3));
				num3 = ASN1DERHelper.NextTagPosition(content, num3);
				num3 = ASN1DERHelper.ContextSpecificFirstTagPosition(content, num3, 0);
				int num4 = 0;
				bool flag = false;
				while (!flag)
				{
					if (num3 != -1 && content[num3] == 48)
					{
						num4++;
						try
						{
							if (num4 != 1)
							{
								throw new NotImplementedException("Non sono supportati file con più di una marca temporale.");
							}
							byte[] array = new byte[ASN1DERHelper.TagLength(content, ASN1DERHelper.SequenceFirstTagPosition(content, num3))];
							Array.Copy(content, ASN1DERHelper.SequenceFirstTagPosition(content, num3), array, 0, array.Length);
							VerifyTimeStamp(list.ToArray(), array, clrMode, verificationTime, cnipaFilePath);
						}
						catch (Exception inner)
						{
							throw new CryptographicException("Fallita verifica della marca temporale N." + num4 + ".", inner);
						}
						num3 = ASN1DERHelper.NextTagPosition(content, num3);
					}
					else
					{
						if (num4 <= 0)
						{
							throw new CryptographicException("Nessun attributo TimeStampAndCRL presente.");
						}
						flag = true;
					}
				}
				return;
			}
			throw new NotImplementedException("TimeStampData con attributo content non valorizzato non supportata.");
		}
		catch (Exception e)
		{
			throw new VerificationFailedException("Verifica del file marcato temporalmente fallita.", e);
		}
	}

	public static void Verify(string filePath, CertHelper.CLRVerification clrMode, DateTime verificationTime, string cnipaFilePath)
	{
		Verify(File.ReadAllBytes(filePath), clrMode, verificationTime, cnipaFilePath);
	}

	public static string InfocertTimeStampCounter(string userName, string passWord)
	{
		WebClient webClient = new WebClient();
		webClient.Proxy = WebRequest.DefaultWebProxy;
		webClient.Proxy.Credentials = CredentialCache.DefaultCredentials;
		webClient.Credentials = CredentialCache.DefaultCredentials;
		webClient.Headers.Add("Content-Type", "application/x-www-form-urlencoded");
		string data = "fTIPO=CONTA-MARCA&fUSER=" + userName + "&fPSW=" + passWord;
		string text = webClient.UploadString("https://marte.infocert.it/cdie/DtsService", data);
		Match match = Regex.Match(text, "DESCR = (.+)", RegexOptions.IgnoreCase);
		if (Regex.IsMatch(text, "MSGNO = 100", RegexOptions.IgnoreCase) && match.Success)
		{
			return match.Groups[1].ToString();
		}
		throw new Exception("Risposta del server inattesa: " + text);
	}
}
