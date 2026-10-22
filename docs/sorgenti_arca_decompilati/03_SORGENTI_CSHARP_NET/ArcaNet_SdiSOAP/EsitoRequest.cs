using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.ServiceModel;

namespace ArcaNet.SdiTrasmissioneFile;

[GeneratedCode("System.ServiceModel", "4.0.0.0")]
[DebuggerStepThrough]
[EditorBrowsable(EditorBrowsableState.Advanced)]
[MessageContract(IsWrapped = false)]
public class EsitoRequest
{
	[MessageBodyMember(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0", Order = 0)]
	public Esito_Type esito;

	public EsitoRequest()
	{
	}

	public EsitoRequest(Esito_Type esito)
	{
		this.esito = esito;
	}
}
