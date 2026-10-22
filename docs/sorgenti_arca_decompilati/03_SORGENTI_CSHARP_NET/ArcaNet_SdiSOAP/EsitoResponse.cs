using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.ServiceModel;

namespace ArcaNet.SdiTrasmissioneFile;

[MessageContract(IsWrapped = false)]
[DebuggerStepThrough]
[EditorBrowsable(EditorBrowsableState.Advanced)]
[GeneratedCode("System.ServiceModel", "4.0.0.0")]
public class EsitoResponse
{
	[MessageBodyMember(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0", Order = 0)]
	public RispostaEsito_Type rispostaEsito;

	public EsitoResponse()
	{
	}

	public EsitoResponse(RispostaEsito_Type rispostaEsito)
	{
		this.rispostaEsito = rispostaEsito;
	}
}
