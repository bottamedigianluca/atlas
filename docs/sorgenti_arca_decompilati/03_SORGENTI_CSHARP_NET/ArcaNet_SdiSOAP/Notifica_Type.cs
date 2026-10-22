using System;
using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.Xml.Schema;
using System.Xml.Serialization;
using ArcaNet.ARKManager_V4;

namespace ArcaNet.SdiTrasmissioneFile;

[Serializable]
[DesignerCategory("code")]
[XmlType(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0")]
[DebuggerStepThrough]
[GeneratedCode("System.Xml", "4.8.3761.0")]
public class Notifica_Type : INotifyPropertyChanged
{
	private string nomeFileField;

	private byte[] fileField;

	[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "normalizedString", Order = 0)]
	public string NomeFile
	{
		get
		{
			return nomeFileField;
		}
		set
		{
			int a_ = 11;
			nomeFileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("ㅾ\uee80\uee82\ue084솆\ue088\ue78a\ue88c", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "base64Binary", Order = 1)]
	public byte[] File
	{
		get
		{
			return fileField;
		}
		set
		{
			int a_ = 18;
			fileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("삅\ue187\ue689\ue98b", a_));
		}
	}

	public event PropertyChangedEventHandler PropertyChanged;

	protected void RaisePropertyChanged(string propertyName)
	{
		this.PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
	}
}
