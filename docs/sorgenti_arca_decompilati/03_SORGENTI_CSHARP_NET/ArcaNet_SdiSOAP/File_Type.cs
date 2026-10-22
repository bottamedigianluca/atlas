using System;
using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.Xml.Schema;
using System.Xml.Serialization;
using ArcaNet.ARKManager_V4;

namespace ArcaNet.SdiTrasmissioneFile;

[Serializable]
[GeneratedCode("System.Xml", "4.8.3761.0")]
[DesignerCategory("code")]
[XmlType(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0")]
[DebuggerStepThrough]
public class File_Type : INotifyPropertyChanged
{
	private string nomeFileField;

	private string tipoFileField;

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
			int a_ = 15;
			nomeFileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("춂\uea84\uea86\uec88춊\ue48c\ue38e\uf490", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, Order = 1)]
	public string TipoFile
	{
		get
		{
			return tipoFileField;
		}
		set
		{
			int a_ = 15;
			tipoFileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("힂\uec84\uf786\ue688춊\ue48c\ue38e\uf490", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, DataType = "base64Binary", Order = 2)]
	public byte[] File
	{
		get
		{
			return fileField;
		}
		set
		{
			int a_ = 10;
			fileField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("㡽\ue97f\uee81\ue183", a_));
		}
	}

	public event PropertyChangedEventHandler PropertyChanged;

	protected void RaisePropertyChanged(string propertyName)
	{
		this.PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
	}
}
