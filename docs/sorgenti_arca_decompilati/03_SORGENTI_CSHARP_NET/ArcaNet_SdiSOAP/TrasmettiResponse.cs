using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.ServiceModel;

namespace ArcaNet.SdiTrasmissioneFile;

[MessageContract(IsWrapped = false)]
[GeneratedCode("System.ServiceModel", "4.0.0.0")]
[EditorBrowsable(EditorBrowsableState.Advanced)]
[DebuggerStepThrough]
public class TrasmettiResponse
{
	[MessageBodyMember(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0", Order = 0)]
	public RispostaFile_Type rispostaFile;

	public TrasmettiResponse()
	{
	}

	public TrasmettiResponse(RispostaFile_Type rispostaFile)
	{
		this.rispostaFile = rispostaFile;
	}
}
