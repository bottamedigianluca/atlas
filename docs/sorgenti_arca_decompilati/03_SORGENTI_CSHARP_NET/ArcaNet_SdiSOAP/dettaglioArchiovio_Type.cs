using System;
using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.Xml.Schema;
using System.Xml.Serialization;
using ArcaNet.ARKManager_V4;

namespace ArcaNet.SdiTrasmissioneFile;

[Serializable]
[DebuggerStepThrough]
[XmlType(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0")]
[GeneratedCode("System.Xml", "4.8.3761.0")]
[DesignerCategory("code")]
public class dettaglioArchiovio_Type : INotifyPropertyChanged
{
	private string nomeFileField;

	private string iDFileField;

	[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "normalizedString", Order = 0)]
	public string NomeFile
	{
		get
		{
			return nomeFileField;
		}
		set
		{
			int a_ = 13;
			nomeFileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("쾀\uec82\ue884\ue286쾈\ue28a\ue18c\uea8e", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "positiveInteger", Order = 1)]
	public string IDFile
	{
		get
		{
			return iDFileField;
		}
		set
		{
			int a_ = 18;
			iDFileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("쾅첇첉\ue58b\ue28d\uf58f", a_));
		}
	}

	public event PropertyChangedEventHandler PropertyChanged;

	protected void RaisePropertyChanged(string propertyName)
	{
		this.PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
	}
}
