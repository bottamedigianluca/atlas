using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.ServiceModel;

namespace ArcaNet.SdiTrasmissioneFile;

[MessageContract(IsWrapped = false)]
[DebuggerStepThrough]
[GeneratedCode("System.ServiceModel", "4.0.0.0")]
[EditorBrowsable(EditorBrowsableState.Advanced)]
public class TrasmettiRequest
{
	[MessageBodyMember(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0", Order = 0)]
	public File_Type file;

	public TrasmettiRequest()
	{
	}

	public TrasmettiRequest(File_Type file)
	{
		this.file = file;
	}
}
