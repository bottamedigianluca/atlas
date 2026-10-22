using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Runtime.CompilerServices;
using System.Xml.Schema;
using System.Xml.Serialization;
using ArcaNet.ARKManager_V4;
using ArcaNet.FatturaPA4Vfp.ServerTypesForAPI;

namespace ArcaNet.FatturaPA4Vfp;

public class WkiHub
{
	public class InviaFatturaResult
	{
		[CompilerGenerated]
		private string a;

		[CompilerGenerated]
		private string b;

		[CompilerGenerated]
		private byte[] c;

		[CompilerGenerated]
		private string d;

		[CompilerGenerated]
		private bool e;

		public string NomeFile
		{
			[CompilerGenerated]
			get
			{
				return a;
			}
			[CompilerGenerated]
			set
			{
				a = value;
			}
		}

		public string ProgressivoFile
		{
			[CompilerGenerated]
			get
			{
				return b;
			}
			[CompilerGenerated]
			set
			{
				b = value;
			}
		}

		public byte[] SignedFile
		{
			[CompilerGenerated]
			get
			{
				return c;
			}
			[CompilerGenerated]
			set
			{
				c = value;
			}
		}

		public string ErrMessage
		{
			[CompilerGenerated]
			get
			{
				return d;
			}
			[CompilerGenerated]
			set
			{
				d = value;
			}
		}

		public bool SignedbyHub
		{
			[CompilerGenerated]
			get
			{
				return e;
			}
			[CompilerGenerated]
			set
			{
				e = value;
			}
		}

		public int RetCode => (!string.IsNullOrEmpty(ErrMessage)) ? 1 : 0;
	}

	[XmlType(Namespace = "http://fattel.wolterskluweritalia.it/")]
	public class ScaricaEsitiFattureResult
	{
		private ScaricaEsitiFattureCodes a;

		private string b;

		private int c;

		private ScaricaEsitiFatturaResult[] d;

		public ScaricaEsitiFattureCodes RetCode
		{
			get
			{
				return a;
			}
			set
			{
				a = value;
			}
		}

		public string ErrMessage
		{
			get
			{
				return b;
			}
			set
			{
				b = value;
			}
		}

		public int EsitiFattureLength
		{
			get
			{
				return c;
			}
			set
			{
				c = value;
			}
		}

		public ScaricaEsitiFatturaResult[] EsitiFatture
		{
			get
			{
				return d;
			}
			set
			{
				d = value;
			}
		}
	}

	[XmlType(Namespace = "http://fattel.wolterskluweritalia.it/")]
	public enum ScaricaEsitiFattureCodes
	{
		OK,
		AuthorizationDenied,
		ProdottoNull,
		ProdottoInvalid,
		LicenzaNull,
		LicenzaTooLong,
		IdFattureProdNullOrZero,
		ProgressiviOrNomiFileNullOrZero,
		ArrayLengthMismatch,
		GenericException
	}

	[XmlType(Namespace = "http://fattel.wolterskluweritalia.it/")]
	public class ScaricaEsitiFatturaResult
	{
		private ScaricaEsitiFatturaCodes a;

		private string b;

		private int c;

		private EsitoFattura[] d;

		public ScaricaEsitiFatturaCodes RetCode
		{
			get
			{
				return a;
			}
			set
			{
				a = value;
			}
		}

		public string ErrMessage
		{
			get
			{
				return b;
			}
			set
			{
				b = value;
			}
		}

		public int EsitiLength
		{
			get
			{
				return c;
			}
			set
			{
				c = value;
			}
		}

		public EsitoFattura[] Esiti
		{
			get
			{
				return d;
			}
			set
			{
				d = value;
			}
		}
	}

	[XmlType(Namespace = "http://fattel.wolterskluweritalia.it/")]
	public enum ScaricaEsitiFatturaCodes
	{
		OK,
		AuthorizationDenied,
		ProdottoNull,
		ProdottoInvalid,
		ProdottoMismatch,
		LicenzaNull,
		LicenzaTooLong,
		LicenzaMismatch,
		IdFatturaProdNull,
		IdFatturaProdTooLong,
		IdFatturaProdMismatch,
		NomeFileNull,
		NomeFileLenError,
		NomeFileShortBadFormat,
		NomeFileLongBadFormat,
		FileFatturaNotFound,
		GenericException
	}

	[XmlType(Namespace = "http://fattel.wolterskluweritalia.it/")]
	public class EsitoFattura
	{
		private string a;

		private DateTime b;

		private DateTime? c;

		private fileSdI_Type d;

		public string TipoMessaggio
		{
			get
			{
				return a;
			}
			set
			{
				a = value;
			}
		}

		public DateTime RicevutaIl
		{
			get
			{
				return b;
			}
			set
			{
				b = value;
			}
		}

		[XmlElement(IsNullable = true)]
		public DateTime? ConsegnataIl
		{
			get
			{
				return c;
			}
			set
			{
				c = value;
			}
		}

		public fileSdI_Type FileSdIType
		{
			get
			{
				return d;
			}
			set
			{
				d = value;
			}
		}
	}

	[XmlType(Namespace = "http://www.fatturapa.gov.it/sdi/ws/trasmissione/v1.0/types")]
	public class fileSdI_Type
	{
		private string a;

		private string b;

		private byte[] c;

		[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "integer")]
		public string IdentificativoSdI
		{
			get
			{
				return a;
			}
			set
			{
				a = value;
			}
		}

		[XmlElement(Form = XmlSchemaForm.Unqualified)]
		public string NomeFile
		{
			get
			{
				return b;
			}
			set
			{
				b = value;
			}
		}

		[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "base64Binary")]
		public byte[] File
		{
			get
			{
				return c;
			}
			set
			{
				c = value;
			}
		}
	}

	[CompilerGenerated]
	private sealed class a
	{
		public string a;

		internal void b(HttpClient A_0)
		{
			A_0.BaseAddress = new Uri(a);
		}
	}

	private readonly FepaHubClient m_a;

	private readonly string m_b;

	private readonly string c;

	private readonly int d;

	private List<Tuple<int, string>> e;

	private List<Tuple<string, string>> f;

	public WkiHub(string prodotto, string licenza, int idDb, string serviceUrl, string pwd)
	{
		int a_ = 17;
		base._002Ector();
		if (string.IsNullOrWhiteSpace(serviceUrl))
		{
			throw new Exception("ServiceUrl non valido!");
		}
		if (!ServicePointManager.SecurityProtocol.HasFlag(SecurityProtocolType.Tls12))
		{
			ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
		}
		string clientPwd = null;
		byte[] clientCert = null;
		if (!pwd.i())
		{
			string msg = b("ws.unlock.token", "http://cert-ws-downloader-todo.uri");
			string text = pwd.Substring(2);
			clientPwd = q8.b(text.Substring(48), text.Substring(0, 48));
			clientCert = q8.a(msg, text);
		}
		this.m_a = new FepaHubClient(delegate(HttpClient A_0)
		{
			A_0.BaseAddress = new Uri(serviceUrl);
		}, clientCert, clientPwd);
		this.m_b = prodotto;
		c = licenza;
		d = idDb;
	}

	private static string b(string token, string baseUrl)
	{
		return Convert.ToBase64String(new byte[2656]
		{
			77, 173, 134, 43, 97, 84, 139, 209, 70, 9,
			182, 160, 184, 174, 103, 189, 107, 134, 8, 174,
			157, 203, 32, 194, 58, 81, 57, 76, 127, 220,
			164, 68, 145, 226, 57, 229, 12, 180, 37, 114,
			187, 2, 185, 56, 72, 157, 24, 191, 75, 66,
			4, 98, 241, 57, 226, 111, 210, 170, 68, 50,
			68, 98, 67, 83, 57, 165, 0, 125, 254, 144,
			100, 105, 98, 72, 156, 216, 110, 125, 43, 94,
			51, 3, 177, 219, 75, 86, 204, 154, 137, 232,
			132, 173, 199, 189, 124, 223, 253, 100, 95, 211,
			80, 247, 131, 137, 229, 120, 205, 84, 189, 208,
			63, 121, 176, 206, 215, 224, 232, 90, 185, 156,
			231, 164, 126, 171, 223, 244, 7, 24, 16, 54,
			140, 144, 124, 71, 148, 78, 80, 190, 113, 145,
			26, 49, 164, 63, 149, 210, 193, 21, 133, 207,
			112, 159, 148, 114, 65, 77, 135, 228, 152, 54,
			204, 217, 66, 110, 176, 125, 214, 177, 229, 246,
			71, 86, 134, 214, 229, 194, 115, 221, 4, 159,
			125, 187, 149, 148, 14, 110, 136, 132, 132, 27,
			133, 204, 129, 113, 66, 88, 28, 248, 123, 244,
			233, 72, 240, 79, 73, 129, 51, 166, 240, 177,
			110, 12, 94, 1, 248, 212, 131, 80, 89, 146,
			10, 67, 78, 187, 230, 71, 159, 45, 119, 83,
			76, 101, 132, 229, 203, 11, 119, 59, 134, 67,
			201, 212, 85, 147, 215, 136, 216, 190, 42, 236,
			201, 192, 128, 174, 10, 220, 76, 0, 167, 199,
			205, 253, 227, 204, 148, 45, 151, 246, 128, 131,
			127, 8, 169, 122, 130, 136, 134, 161, 137, 73,
			164, 216, 1, 230, 182, 82, 231, 233, 194, 17,
			183, 144, 138, 147, 206, 164, 160, 209, 196, 0,
			194, 248, 178, 80, 130, 33, 132, 7, 247, 79,
			231, 16, 60, 102, 132, 139, 250, 165, 145, 132,
			229, 23, 49, 26, 169, 149, 236, 41, 252, 71,
			234, 163, 85, 142, 208, 243, 136, 115, 221, 69,
			54, 170, 239, 73, 168, 78, 152, 214, 222, 36,
			66, 79, 159, 8, 98, 118, 72, 181, 146, 190,
			171, 229, 57, 227, 47, 33, 147, 31, 180, 251,
			251, 147, 253, 221, 60, 10, 187, 58, 161, 209,
			40, 62, 58, 157, 60, 180, 197, 196, 252, 50,
			75, 2, 254, 119, 217, 195, 204, 18, 88, 202,
			11, 24, 219, 67, 191, 231, 91, 115, 249, 137,
			134, 131, 31, 164, 185, 8, 149, 143, 123, 11,
			107, 104, 82, 241, 223, 231, 211, 101, 77, 233,
			200, 209, 71, 41, 54, 131, 112, 248, 53, 67,
			56, 209, 242, 101, 43, 230, 138, 141, 108, 195,
			7, 94, 94, 187, 28, 179, 199, 241, 213, 130,
			121, 120, 230, 10, 229, 16, 208, 155, 167, 0,
			119, 24, 255, 153, 75, 239, 46, 89, 57, 33,
			139, 180, 97, 162, 115, 226, 188, 203, 61, 235,
			173, 126, 180, 62, 211, 225, 220, 41, 44, 61,
			209, 71, 208, 44, 37, 49, 29, 27, 89, 8,
			122, 105, 162, 210, 195, 163, 107, 197, 211, 165,
			187, 97, 121, 100, 87, 183, 121, 173, 36, 206,
			176, 87, 19, 3, 14, 180, 1, 175, 30, 119,
			254, 182, 82, 71, 86, 102, 116, 225, 118, 51,
			36, 176, 96, 36, 12, 68, 70, 171, 249, 85,
			71, 164, 162, 118, 73, 92, 76, 3, 144, 188,
			99, 0, 207, 240, 140, 47, 254, 34, 74, 159,
			122, 66, 7, 228, 210, 67, 167, 131, 128, 248,
			15, 96, 242, 231, 152, 235, 45, 127, 113, 233,
			91, 99, 27, 56, 14, 28, 152, 147, 96, 188,
			150, 141, 114, 53, 156, 27, 135, 87, 253, 181,
			4, 172, 66, 72, 17, 252, 183, 145, 178, 246,
			235, 207, 67, 212, 145, 87, 15, 123, 54, 226,
			91, 105, 160, 23, 102, 120, 53, 81, 183, 254,
			26, 84, 250, 12, 107, 42, 238, 194, 237, 148,
			15, 59, 130, 36, 231, 117, 74, 251, 195, 12,
			88, 208, 229, 138, 219, 76, 198, 247, 160, 72,
			26, 98, 83, 114, 247, 85, 186, 172, 118, 231,
			12, 157, 143, 9, 113, 12, 168, 171, 189, 164,
			119, 29, 254, 156, 155, 241, 108, 88, 193, 3,
			212, 24, 88, 221, 123, 125, 43, 235, 146, 217,
			103, 157, 83, 28, 104, 11, 27, 149, 57, 234,
			123, 82, 238, 153, 124, 95, 191, 15, 144, 71,
			115, 182, 207, 108, 138, 196, 84, 200, 83, 182,
			59, 136, 217, 121, 105, 89, 210, 204, 115, 150,
			200, 242, 97, 192, 229, 173, 6, 104, 246, 36,
			173, 81, 214, 69, 154, 77, 197, 176, 105, 15,
			54, 200, 226, 103, 208, 159, 228, 133, 182, 58,
			135, 47, 241, 186, 50, 149, 119, 236, 119, 32,
			232, 222, 180, 66, 15, 122, 232, 190, 45, 32,
			34, 245, 125, 173, 6, 112, 222, 65, 131, 21,
			240, 197, 106, 79, 133, 45, 1, 111, 40, 211,
			96, 40, 224, 215, 168, 168, 38, 162, 122, 186,
			50, 203, 197, 199, 100, 7, 83, 146, 88, 93,
			109, 231, 131, 168, 43, 197, 117, 209, 235, 250,
			11, 213, 103, 57, 219, 187, 72, 190, 237, 186,
			37, 172, 101, 114, 240, 140, 16, 225, 167, 150,
			110, 173, 52, 234, 249, 28, 185, 214, 177, 175,
			60, 186, 127, 24, 80, 37, 229, 216, 106, 224,
			93, 42, 242, 166, 112, 216, 1, 123, 219, 147,
			44, 237, 179, 0, 74, 6, 150, 189, 251, 234,
			234, 204, 145, 198, 48, 237, 98, 144, 162, 253,
			25, 55, 128, 36, 86, 47, 51, 62, 246, 222,
			112, 5, 220, 203, 33, 173, 253, 166, 180, 189,
			84, 94, 15, 44, 220, 233, 53, 91, 207, 139,
			168, 116, 141, 87, 13, 182, 72, 6, 219, 81,
			122, 233, 249, 211, 145, 3, 96, 46, 62, 210,
			239, 54, 155, 146, 132, 232, 117, 38, 149, 8,
			25, 220, 167, 13, 9, 102, 46, 15, 65, 164,
			131, 131, 231, 12, 92, 150, 80, 194, 133, 163,
			49, 92, 43, 40, 36, 98, 228, 104, 113, 122,
			39, 146, 139, 12, 21, 86, 184, 92, 49, 223,
			8, 38, 205, 87, 98, 87, 96, 128, 125, 2,
			113, 128, 181, 205, 163, 187, 18, 240, 216, 161,
			201, 157, 123, 189, 4, 63, 5, 210, 195, 6,
			123, 131, 52, 153, 121, 23, 238, 200, 90, 140,
			207, 28, 82, 214, 173, 212, 215, 215, 37, 204,
			220, 159, 54, 44, 181, 240, 217, 182, 209, 27,
			195, 237, 116, 91, 90, 78, 205, 125, 74, 27,
			119, 31, 214, 157, 160, 97, 64, 62, 235, 101,
			183, 187, 152, 71, 52, 250, 79, 68, 187, 88,
			192, 22, 248, 8, 141, 107, 102, 68, 203, 203,
			56, 109, 111, 84, 240, 180, 5, 37, 152, 63,
			8, 140, 206, 217, 184, 233, 90, 38, 185, 197,
			198, 54, 173, 49, 0, 104, 229, 246, 174, 229,
			113, 77, 138, 103, 54, 38, 185, 195, 75, 71,
			114, 210, 236, 59, 189, 33, 64, 219, 33, 108,
			188, 209, 7, 105, 94, 58, 15, 83, 174, 217,
			160, 37, 176, 78, 203, 185, 215, 161, 36, 250,
			87, 100, 160, 131, 39, 233, 213, 168, 134, 59,
			17, 125, 77, 187, 123, 8, 30, 47, 150, 218,
			17, 57, 120, 233, 223, 82, 32, 187, 80, 22,
			20, 6, 164, 3, 160, 239, 15, 61, 169, 73,
			106, 4, 86, 112, 227, 211, 8, 18, 66, 76,
			140, 150, 3, 164, 222, 114, 253, 187, 190, 111,
			79, 96, 100, 168, 121, 9, 8, 56, 109, 239,
			139, 99, 32, 230, 12, 132, 80, 30, 211, 24,
			33, 22, 30, 15, 127, 106, 135, 39, 43, 202,
			232, 116, 110, 181, 146, 110, 116, 133, 168, 141,
			178, 65, 8, 123, 121, 63, 221, 114, 18, 108,
			114, 117, 41, 135, 75, 231, 52, 11, 211, 194,
			28, 107, 221, 121, 56, 190, 110, 217, 17, 45,
			55, 154, 8, 62, 16, 23, 88, 133, 137, 100,
			248, 241, 96, 191, 147, 241, 121, 51, 15, 192,
			53, 252, 21, 92, 221, 77, 228, 215, 223, 109,
			189, 218, 186, 210, 40, 67, 238, 23, 141, 22,
			85, 148, 253, 206, 1, 205, 21, 84, 23, 125,
			181, 88, 160, 235, 216, 31, 155, 218, 104, 243,
			246, 103, 54, 225, 96, 12, 23, 8, 169, 191,
			212, 118, 201, 93, 165, 13, 131, 175, 250, 244,
			184, 230, 209, 108, 218, 1, 117, 205, 126, 40,
			137, 196, 253, 66, 22, 23, 215, 16, 60, 135,
			71, 227, 70, 56, 111, 183, 130, 66, 59, 147,
			195, 151, 189, 42, 250, 146, 54, 151, 247, 184,
			184, 187, 52, 247, 35, 52, 211, 207, 211, 93,
			82, 190, 241, 82, 250, 18, 125, 163, 201, 217,
			15, 81, 18, 2, 68, 107, 117, 127, 96, 12,
			76, 186, 235, 29, 192, 97, 33, 21, 126, 135,
			204, 186, 2, 187, 77, 73, 204, 244, 245, 143,
			157, 18, 236, 167, 222, 184, 92, 98, 47, 5,
			18, 123, 239, 125, 253, 247, 172, 184, 83, 215,
			228, 247, 146, 99, 35, 194, 148, 29, 14, 236,
			112, 225, 173, 9, 214, 55, 120, 209, 19, 14,
			151, 92, 232, 223, 19, 49, 141, 207, 242, 180,
			133, 84, 237, 254, 182, 36, 186, 113, 45, 25,
			170, 205, 64, 75, 123, 33, 30, 158, 185, 169,
			78, 206, 31, 184, 80, 166, 3, 120, 255, 64,
			147, 25, 223, 72, 111, 229, 96, 145, 189, 150,
			245, 27, 44, 78, 183, 132, 72, 85, 116, 199,
			87, 112, 58, 34, 166, 9, 191, 241, 53, 194,
			133, 37, 131, 245, 42, 218, 127, 156, 235, 212,
			209, 202, 100, 151, 136, 180, 188, 59, 139, 191,
			10, 120, 90, 211, 1, 239, 19, 146, 231, 181,
			195, 75, 206, 117, 175, 230, 243, 25, 5, 164,
			152, 196, 250, 41, 53, 250, 123, 192, 85, 55,
			142, 156, 52, 213, 135, 251, 132, 120, 111, 211,
			237, 133, 131, 60, 86, 119, 153, 136, 24, 113,
			190, 189, 228, 219, 57, 205, 224, 35, 206, 241,
			35, 198, 45, 75, 3, 143, 93, 129, 52, 173,
			1, 153, 23, 108, 217, 159, 190, 188, 232, 193,
			137, 170, 43, 138, 74, 13, 123, 35, 102, 137,
			201, 207, 169, 153, 200, 221, 168, 31, 53, 77,
			47, 25, 68, 160, 87, 77, 108, 243, 195, 167,
			123, 108, 203, 79, 49, 78, 136, 51, 6, 164,
			135, 125, 254, 233, 104, 224, 30, 203, 239, 217,
			78, 59, 235, 110, 214, 212, 226, 235, 11, 230,
			145, 10, 135, 73, 48, 61, 218, 50, 253, 106,
			95, 75, 251, 77, 39, 147, 154, 164, 213, 78,
			148, 143, 185, 155, 192, 247, 164, 8, 178, 122,
			8, 119, 214, 221, 109, 211, 248, 125, 7, 81,
			22, 227, 80, 107, 246, 185, 43, 95, 66, 49,
			28, 119, 169, 117, 86, 108, 27, 100, 94, 70,
			174, 167, 9, 250, 218, 109, 205, 144, 143, 63,
			115, 42, 157, 8, 149, 215, 176, 79, 62, 148,
			99, 190, 144, 148, 255, 125, 53, 47, 239, 190,
			92, 237, 119, 192, 30, 204, 224, 209, 40, 56,
			21, 136, 87, 162, 74, 181, 236, 87, 113, 18,
			47, 1, 68, 142, 248, 57, 245, 221, 190, 66,
			85, 30, 40, 92, 21, 106, 115, 45, 223, 93,
			231, 201, 235, 139, 221, 37, 23, 141, 25, 8,
			71, 13, 69, 43, 125, 133, 27, 220, 167, 241,
			20, 87, 74, 63, 253, 132, 52, 238, 143, 216,
			13, 168, 161, 125, 84, 152, 90, 225, 172, 229,
			76, 210, 42, 150, 158, 147, 83, 36, 217, 119,
			159, 255, 255, 66, 72, 34, 205, 228, 229, 75,
			83, 49, 71, 230, 166, 221, 180, 180, 200, 90,
			249, 117, 51, 245, 208, 222, 239, 247, 216, 105,
			172, 251, 18, 15, 65, 56, 145, 111, 46, 54,
			173, 160, 191, 185, 229, 72, 19, 177, 182, 71,
			175, 103, 226, 126, 9, 154, 139, 111, 132, 105,
			232, 246, 229, 154, 186, 204, 148, 176, 12, 123,
			155, 22, 70, 179, 173, 68, 102, 155, 125, 82,
			132, 81, 66, 75, 21, 248, 64, 154, 176, 144,
			197, 190, 119, 49, 93, 197, 252, 184, 163, 95,
			249, 190, 3, 69, 125, 112, 121, 228, 123, 140,
			37, 110, 50, 9, 62, 252, 64, 154, 114, 242,
			93, 150, 96, 232, 141, 68, 97, 155, 83, 148,
			191, 132, 45, 43, 226, 204, 247, 223, 131, 236,
			67, 237, 73, 180, 171, 53, 66, 88, 41, 22,
			93, 178, 5, 211, 111, 11, 87, 211, 164, 155,
			221, 94, 234, 95, 168, 107, 174, 195, 10, 173,
			47, 171, 52, 185, 50, 235, 57, 101, 24, 197,
			68, 195, 182, 252, 190, 135, 162, 208, 195, 153,
			233, 24, 121, 67, 155, 72, 143, 138, 189, 143,
			19, 33, 43, 232, 246, 142, 187, 91, 222, 187,
			125, 100, 217, 214, 146, 123, 108, 100, 97, 251,
			114, 153, 138, 243, 200, 150, 12, 128, 174, 3,
			110, 176, 45, 191, 163, 38, 62, 247, 232, 246,
			214, 245, 116, 149, 73, 122, 251, 135, 94, 105,
			222, 58, 131, 12, 233, 150, 214, 17, 186, 188,
			29, 9, 213, 146, 174, 171, 47, 224, 231, 65,
			222, 167, 68, 109, 103, 185, 98, 123, 187, 69,
			52, 58, 139, 52, 38, 243, 44, 27, 235, 140,
			19, 63, 144, 128, 201, 237, 116, 245, 139, 186,
			161, 253, 115, 216, 241, 198, 48, 172, 203, 181,
			236, 11, 15, 30, 113, 98, 69, 25, 153, 31,
			253, 215, 28, 17, 214, 194, 237, 132, 100, 101,
			203, 48, 173, 157, 190, 93, 65, 254, 214, 29,
			68, 180, 110, 67, 251, 26, 171, 2, 0, 125,
			144, 80, 7, 225, 39, 223, 208, 129, 17, 174,
			139, 87, 35, 45, 46, 6, 97, 246, 69, 208,
			244, 225, 200, 130, 23, 121, 114, 113, 145, 30,
			141, 89, 222, 95, 39, 54, 61, 78, 244, 152,
			36, 144, 161, 250, 53, 158, 65, 45, 151, 0,
			134, 7, 234, 143, 93, 243, 188, 37, 182, 245,
			2, 21, 143, 172, 194, 46, 87, 223, 176, 101,
			220, 243, 13, 254, 28, 87, 226, 30, 170, 151,
			177, 94, 96, 51, 130, 87, 4, 25, 101, 118,
			28, 70, 196, 1, 179, 108, 157, 56, 199, 120,
			243, 4, 51, 188, 195, 26, 20, 173, 47, 123,
			196, 5, 83, 179, 229, 142, 200, 56, 211, 190,
			205, 93, 3, 134, 79, 44, 47, 12, 21, 86,
			53, 3, 166, 36, 86, 62, 143, 64, 31, 60,
			71, 80, 180, 166, 244, 149, 13, 224, 135, 11,
			234, 97, 225, 18, 118, 47, 108, 214, 103, 232,
			133, 134, 6, 17, 220, 31, 141, 20, 113, 205,
			36, 40, 200, 242, 240, 31, 147, 80, 6, 18,
			237, 98, 169, 75, 165, 62, 115, 119, 59, 17,
			155, 106, 81, 7, 82, 110, 252, 147, 210, 126,
			112, 90, 245, 192, 218, 20, 140, 214, 40, 225,
			65, 249, 110, 180, 46, 116, 91, 47, 161, 78,
			230, 192, 138, 132, 48, 229, 45, 213, 61, 252,
			84, 189, 81, 220, 254, 64, 64, 146, 142, 168,
			197, 213, 212, 216, 16, 155, 54, 187, 143, 245,
			224, 78, 41, 70, 135, 170, 177, 150, 87, 192,
			108, 206, 226, 159, 208, 17, 228, 156, 226, 15,
			55, 203, 237, 191, 107, 199, 80, 78, 111, 186,
			39, 20, 187, 77, 239, 102, 160, 34, 107, 104,
			92, 7, 83, 247, 102, 116, 71, 70, 247, 90,
			157, 97, 253, 204, 101, 12, 4, 200, 207, 134,
			77, 16, 188, 247, 244, 82, 204, 72, 10, 70,
			142, 28, 32, 172, 177, 188, 44, 221, 249, 8,
			212, 171, 206, 122, 144, 108, 117, 63, 135, 232,
			33, 72, 222, 17, 115, 193, 220, 40, 170, 241,
			109, 110, 75, 133, 189, 18
		});
	}

	public InviaFatturaResult InviaFattura(string udDoTes, string fileXmlUri, bool applySign)
	{
		int a_ = 4;
		string idFatturaProd = udDoTes ?? "";
		try
		{
			string formatoFile = ((Path.GetExtension(fileXmlUri) == ".xml") ? "PlainXml" : "Cades");
			InvioResult invioResult = this.m_a.FattureAttiveInvio(this.m_b, c, idFatturaProd, formatoFile, File.ReadAllBytes(fileXmlUri), applySign);
			return new InviaFatturaResult
			{
				ErrMessage = string.Empty,
				NomeFile = invioResult.NomeFile,
				ProgressivoFile = invioResult.ProgressivoFile,
				SignedFile = invioResult.SignedFile,
				SignedbyHub = invioResult.SignedbyHub
			};
		}
		catch (Exception a_2)
		{
			return new InviaFatturaResult
			{
				ErrMessage = (a_2.a(false) ?? "")
			};
		}
	}

	public ScaricaEsitiFatturaResult ScaricaEsitiFatturaById(int idDoTes, string nomeFatturaPA)
	{
		int a_ = 4;
		string idFatturaProd = string.Format("{0}.{1}", d, idDoTes);
		return a(idFatturaProd, nomeFatturaPA);
	}

	public ScaricaEsitiFatturaResult ScaricaEsitiFatturaByGuid(string udFTE, string nomeFatturaPA)
	{
		string idFatturaProd = udFTE ?? "";
		return a(idFatturaProd, nomeFatturaPA);
	}

	private ScaricaEsitiFatturaResult a(string idFatturaProd, string nomeFatturaPA)
	{
		try
		{
			List<EsitoResult> list = this.m_a.FattureAttiveEsiti(this.m_b, c, idFatturaProd, nomeFatturaPA);
			return new ScaricaEsitiFatturaResult
			{
				RetCode = ScaricaEsitiFatturaCodes.OK,
				ErrMessage = string.Empty,
				EsitiLength = list.Count,
				Esiti = list.Select((EsitoResult A_0) => new EsitoFattura
				{
					TipoMessaggio = A_0.TipoMessaggio,
					RicevutaIl = A_0.RicevutaIl,
					ConsegnataIl = A_0.ConsegnataIl,
					FileSdIType = new fileSdI_Type
					{
						IdentificativoSdI = A_0.FileSdIType?.IdentificativoSdI,
						NomeFile = A_0.FileSdIType?.NomeFile,
						File = A_0.FileSdIType?.File
					}
				}).ToArray()
			};
		}
		catch (Exception a_)
		{
			return new ScaricaEsitiFatturaResult
			{
				RetCode = ScaricaEsitiFatturaCodes.GenericException,
				ErrMessage = (a_.a(false) ?? "")
			};
		}
	}

	public int ScaricaEsitiFattureById_Collect(int idDoTes, string nomeFatturaPA)
	{
		if (e == null)
		{
			e = new List<Tuple<int, string>>();
		}
		e.Add(new Tuple<int, string>(idDoTes, nomeFatturaPA));
		return e.Count;
	}

	public int ScaricaEsitiFattureByGuid_Collect(string udFTE, string nomeFatturaPA)
	{
		if (f == null)
		{
			f = new List<Tuple<string, string>>();
		}
		f.Add(new Tuple<string, string>(udFTE, nomeFatturaPA));
		return f.Count;
	}

	public ScaricaEsitiFattureResult ScaricaEsitiFattureById_Execute()
	{
		if (e == null)
		{
			return new ScaricaEsitiFattureResult();
		}
		List<ScaricaEsitiFatturaResult> list = new List<ScaricaEsitiFatturaResult>();
		for (int i = 0; i < e.Count; i++)
		{
			Tuple<int, string> tuple = e[i];
			ScaricaEsitiFatturaResult item = ScaricaEsitiFatturaById(tuple.Item1, tuple.Item2);
			list.Add(item);
		}
		e = null;
		return new ScaricaEsitiFattureResult
		{
			RetCode = ScaricaEsitiFattureCodes.OK,
			ErrMessage = string.Empty,
			EsitiFattureLength = list.Count,
			EsitiFatture = list.ToArray()
		};
	}

	public ScaricaEsitiFattureResult ScaricaEsitiFattureByGuid_Execute()
	{
		if (f == null)
		{
			return new ScaricaEsitiFattureResult();
		}
		List<ScaricaEsitiFatturaResult> list = new List<ScaricaEsitiFatturaResult>();
		for (int i = 0; i < f.Count; i++)
		{
			Tuple<string, string> tuple = f[i];
			ScaricaEsitiFatturaResult item = ScaricaEsitiFatturaByGuid(tuple.Item1, tuple.Item2);
			list.Add(item);
		}
		f = null;
		return new ScaricaEsitiFattureResult
		{
			RetCode = ScaricaEsitiFattureCodes.OK,
			ErrMessage = string.Empty,
			EsitiFattureLength = list.Count,
			EsitiFatture = list.ToArray()
		};
	}

	public VfpResult FileFatturaFromIdFatturaProd(string cIdFatturaProd)
	{
		try
		{
			string result = this.m_a.FileFatturaFromIdFatturaProdv4_4Vfp(this.m_b, c, cIdFatturaProd);
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result
			};
		}
		catch (Exception a_)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_.a(false),
				Result = string.Empty
			};
		}
	}

	public VfpResult ScaricaFatturaAttiva(string nomeFileFattura)
	{
		try
		{
			string result = this.m_a.ScaricaFatturaAttiva_4Vfp(this.m_b, c, nomeFileFattura);
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result
			};
		}
		catch (Exception a_)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_.a(false),
				Result = string.Empty
			};
		}
	}

	public VfpResult ListaFatturePassive(string cCodiceFPR_WKI, string cPartitaIVA, int nIdFatturaRxDa, int nIdFatturaRxA, string cDataFatturaRxDa, string cDataFatturaRxA)
	{
		int a_ = 7;
		try
		{
			ParamsFattureRx paramsFattureRx = new ParamsFattureRx();
			paramsFattureRx.PartiteIva = new string[1] { cPartitaIVA };
			ParamsFattureRx paramsFattureRx2 = paramsFattureRx;
			if (nIdFatturaRxDa >= 0)
			{
				paramsFattureRx2.IdFatturaRxDa = nIdFatturaRxDa;
			}
			if (nIdFatturaRxA > 0)
			{
				paramsFattureRx2.IdFatturaRxA = nIdFatturaRxA;
			}
			if (cDataFatturaRxDa != null && DateTime.TryParseExact(cDataFatturaRxDa, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var result))
			{
				paramsFattureRx2.DataFatturaDa = result;
			}
			if (cDataFatturaRxA != null && DateTime.TryParseExact(cDataFatturaRxA, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var result2))
			{
				paramsFattureRx2.DataFatturaA = result2;
			}
			string result3 = this.m_a.FatturePassiveLista4Vfp(this.m_b, c, cCodiceFPR_WKI, paramsFattureRx2);
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result3
			};
		}
		catch (Exception a_2)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_2.a(false),
				Result = string.Empty
			};
		}
	}

	public VfpResult ScaricaFatturaPassiva(string cCodiceFPR_WKI, string cPartitaIVA, int nIdFatturaRx)
	{
		try
		{
			string result = this.m_a.FatturePassiveRicevi4Vfp(this.m_b, c, cCodiceFPR_WKI, cPartitaIVA, nIdFatturaRx);
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result
			};
		}
		catch (Exception a_)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_.a(false),
				Result = string.Empty
			};
		}
	}

	public VfpResult CreaEULA(string cCognome, string cNome, string cCodiceFiscale, string cDomicilio, string cEmail, string cPartitaIva_Azienda, string cRagioneSociale_Azienda)
	{
		try
		{
			Eula eula = new Eula
			{
				Licenza = c,
				Prodotto = this.m_b,
				Cognome = cCognome,
				Nome = cNome,
				CodiceFiscale = cCodiceFiscale,
				Email = cEmail,
				Domicilio = cDomicilio,
				PIvaManlevata = cPartitaIva_Azienda,
				PIvaManRagSoc = cRagioneSociale_Azienda
			};
			string result = this.m_a.EulaInsert(eula);
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result
			};
		}
		catch (Exception a_)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_.a(false),
				Result = string.Empty
			};
		}
	}

	public VfpResult ValidaEULA(string cOTP, int nIdEula)
	{
		try
		{
			string result = this.m_a.EulaValidate4Vfp(this.m_b, c, cOTP, nIdEula);
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result
			};
		}
		catch (Exception a_)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_.a(false),
				Result = string.Empty
			};
		}
	}

	public VfpResult StatoEULA(string cPartitaIVA)
	{
		try
		{
			string result = this.m_a.EulaStatus4Vfp(this.m_b, c, cPartitaIVA);
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result
			};
		}
		catch (Exception a_)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_.a(false),
				Result = string.Empty
			};
		}
	}

	public VfpResult HealthCheck()
	{
		try
		{
			string result = this.m_a.HealthCheck4Vfp();
			return new VfpResult
			{
				Success = true,
				Error = string.Empty,
				Result = result
			};
		}
		catch (Exception a_)
		{
			return new VfpResult
			{
				Success = false,
				Error = a_.a(false),
				Result = string.Empty
			};
		}
	}
}
