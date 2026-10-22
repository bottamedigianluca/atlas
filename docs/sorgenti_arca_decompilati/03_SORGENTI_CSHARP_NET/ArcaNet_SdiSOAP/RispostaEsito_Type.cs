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
[DesignerCategory("code")]
[XmlType(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0")]
[GeneratedCode("System.Xml", "4.8.3761.0")]
public class RispostaEsito_Type : INotifyPropertyChanged
{
	private string esitoField;

	private Notifica_Type notificaField;

	private dettaglioArchiovio_Type[] dettaglioArchivioField;

	private string erroreField;

	[XmlElement(Form = XmlSchemaForm.Unqualified, Order = 0)]
	public string Esito
	{
		get
		{
			return esitoField;
		}
		set
		{
			int a_ = 17;
			esitoField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("삄\uf486\ue088ﾊ\ue28c", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, Order = 1)]
	public Notifica_Type Notifica
	{
		get
		{
			return notificaField;
		}
		set
		{
			int a_ = 8;
			notificaField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("㉻ᅽ\uf47f\ueb81\ue283\uef85\ueb87\ueb89", a_));
		}
	}

	[XmlElement("DettaglioArchivio", Form = XmlSchemaForm.Unqualified, Order = 2)]
	public dettaglioArchiovio_Type[] DettaglioArchivio
	{
		get
		{
			return dettaglioArchivioField;
		}
		set
		{
			int a_ = 16;
			dettaglioArchivioField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("삃\ue385ﲇﺉ\ued8b\ue98dﲏﮑﮓ힕\uea97蓮\uf49b\uf79d횟쮡쮣", a_));
		}
	}

	[XmlElement(Form = XmlSchemaForm.Unqualified, Order = 3)]
	public string Errore
	{
		get
		{
			return erroreField;
		}
		set
		{
			int a_ = 14;
			erroreField = value;
			RaisePropertyChanged(GetDocTypeOnLTAUserResult4Vfp.b("잁\uf683\uf485\ue787\uf889\ue98b", a_));
		}
	}

	public event PropertyChangedEventHandler PropertyChanged;

	protected void RaisePropertyChanged(string propertyName)
	{
		this.PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
	}
}
