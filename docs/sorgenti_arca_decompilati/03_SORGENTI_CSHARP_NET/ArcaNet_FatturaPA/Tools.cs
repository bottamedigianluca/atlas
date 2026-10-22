using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography.Pkcs;
using System.Xml.Schema;
using ArcaNet.ARKManager_V4;
using ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_0;
using ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_1;
using ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_2;
using WKISigner;

namespace ArcaNet.FatturaPA4Vfp;

public class Tools
{
	public readonly int FepaXsdByDate;

	public readonly int FepaXsd10 = 1;

	public readonly int FepaXsd11 = 2;

	public readonly int FepaXsd12 = 3;

	private CmsSigner a;

	public string XsdValidation(string fileXmlUri, FepaXsdVersion fepaXsd)
	{
		int a_ = 4;
		try
		{
			List<string> list = ((fepaXsd == FepaXsdVersion.FepaXsd10 || (fepaXsd == FepaXsdVersion.FepaXsdByDate && DateTime.Today < new DateTime(2015, 2, 2))) ? ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_0.FatturaElettronicaType.XsdValidateFile(fileXmlUri) : ((fepaXsd == FepaXsdVersion.FepaXsd11 || (fepaXsd == FepaXsdVersion.FepaXsdByDate && DateTime.Today < new DateTime(2017, 1, 1))) ? ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_1.FatturaElettronicaType.XsdValidateFile(fileXmlUri) : ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_2.FatturaElettronicaType.XsdValidateFile(fileXmlUri))).Select(delegate(ValidationEventArgs A_0)
			{
				int a_3 = 6;
				return string.Format(((A_0.Severity == XmlSeverityType.Error) ? GetDocTypeOnLTAUserResult4Vfp.b("㽹\u0e7b౽\uef7f\uf081\ue183ꚅ\ue187\ue489겋", a_3) : GetDocTypeOnLTAUserResult4Vfp.b("㑹፻ၽꁿ\uf481\ue583\uea85\ue187\uee89\ue38b꺍憐ﲑ뒓", a_3)) + GetDocTypeOnLTAUserResult4Vfp.b("剹ݻ乽ﵿ꺁ﾃ랅\uf587ꎉ뚋꺍\ueb8fꂑ\ue993", a_3), A_0.Exception.LineNumber, A_0.Exception.LinePosition, A_0.Message);
			}).ToList();
			return (list.Count == 0) ? string.Empty : list.Aggregate(delegate(string s1, string s2)
			{
				int a_3 = 15;
				return s1 + GetDocTypeOnLTAUserResult4Vfp.b("躂辄", a_3) + s2;
			});
		}
		catch (Exception a_2)
		{
			return a_2.a(GetDocTypeOnLTAUserResult4Vfp.b("牷睹", a_));
		}
	}

	public string ControlliSdiValidation(string fileXmlUri, FepaXsdVersion fepaXsd)
	{
		int a_ = 5;
		try
		{
			List<string> list = ((fepaXsd == FepaXsdVersion.FepaXsd10 || (fepaXsd == FepaXsdVersion.FepaXsdByDate && DateTime.Today < new DateTime(2015, 2, 2))) ? ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_0.FatturaElettronicaType.EseguiControlliSdi(ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_0.FatturaElettronicaType.DeserializeFromFile(fileXmlUri)) : ((fepaXsd == FepaXsdVersion.FepaXsd11 || (fepaXsd == FepaXsdVersion.FepaXsdByDate && DateTime.Today < new DateTime(2017, 1, 1))) ? ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_1.FatturaElettronicaType.EseguiControlliSdi(ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_1.FatturaElettronicaType.DeserializeFromFile(fileXmlUri)) : ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_2.FatturaElettronicaType.EseguiControlliSdi(ArcaNet.FatturaPA4Vfp.FatturaPATypes.Fattura_v1_2.FatturaElettronicaType.DeserializeFromFile(fileXmlUri))));
			return (list.Count == 0) ? string.Empty : list.Aggregate(delegate(string s1, string s2)
			{
				int a_3 = 11;
				return s1 + GetDocTypeOnLTAUserResult4Vfp.b("牾讀", a_3) + s2;
			});
		}
		catch (Exception a_2)
		{
			return a_2.a(GetDocTypeOnLTAUserResult4Vfp.b("獸発", a_));
		}
	}

	public bool FirmaFattura(string fileXmlUri)
	{
		return ApplySignature(fileXmlUri);
	}

	public bool ChooseCertificate(bool chooseAgain)
	{
		return ChooseCertificate2(chooseAgain, 0);
	}

	public bool ChooseCertificate2(bool chooseAgain, int hWndParent)
	{
		if (a != null && !chooseAgain)
		{
			return true;
		}
		a = CadesSigner.BuildCmsSigner(new IntPtr(hWndParent));
		return a != null;
	}

	public bool ApplySignature(string inputFileUri)
	{
		int a_ = 11;
		if (!ChooseCertificate(chooseAgain: false))
		{
			return false;
		}
		byte[] bytes = CadesSigner.Sign(inputFileUri, a);
		File.WriteAllBytes(inputFileUri + GetDocTypeOnLTAUserResult4Vfp.b("兾\uf180뒂\ue884", a_), bytes);
		return true;
	}

	public string ExtractContent(string inputFileUri, string outputFileUri)
	{
		int a_ = 0;
		try
		{
			byte[] source = File.ReadAllBytes(inputFileUri);
			source = FepaFileUtils.SmartDecode(source);
			File.WriteAllBytes(outputFileUri, source);
			return string.Empty;
		}
		catch (Exception a_2)
		{
			return a_2.a(GetDocTypeOnLTAUserResult4Vfp.b("繳筵", a_));
		}
	}
}
