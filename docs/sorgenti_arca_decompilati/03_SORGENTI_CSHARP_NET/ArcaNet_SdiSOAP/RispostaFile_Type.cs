using System;
using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.Xml.Schema;
using System.Xml.Serialization;
using ArcaNet.ARKManager_V4;

namespace ArcaNet.SdiTrasmissioneFile;

[Serializable]
[XmlType(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0")]
[GeneratedCode("System.Xml", "4.8.3761.0")]
[DebuggerStepThrough]
[DesignerCategory("code")]
public class RispostaFile_Type : INotifyPropertyChanged
{
	private string iDFileField;

	private DateTime dataOraRicezioneField;

	private string erroreField;

	[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "positiveInteger", Order = 0)]
	public string IDFile
	{
		get
		{
			return iDFileField;
		}
		set
		{
			int a_ = 11;
			iDFileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("㙾얀얂\uec84\ueb86\uec88", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, Order = 1)]
	public DateTime DataOraRicezione
	{
		get
		{
			return dataOraRicezioneField;
		}
		set
		{
			int a_ = 18;
			dataOraRicezioneField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("슅\ue987ﺉ\ued8b속\ue28f\uf391욓ﾕﮗﾙ\ue69b\uf79d쾟첡솣", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, Order = 2)]
	public string Errore
	{
		get
		{
			return erroreField;
		}
		set
		{
			int a_ = 1;
			erroreField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("ぴն\u0b78ᑺ\u0f7c\u1a7e", a_));
		}
	}

	public event PropertyChangedEventHandler PropertyChanged;

	protected void RaisePropertyChanged(string propertyName)
	{
		this.PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
	}
}
