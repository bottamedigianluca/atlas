using System.CodeDom.Compiler;
using System.ServiceModel;
using System.Threading.Tasks;

namespace ArcaNet.SdiTrasmissioneFile;

[GeneratedCode("System.ServiceModel", "4.0.0.0")]
[ServiceContract(Namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0", ConfigurationName = "SdiTrasmissioneFile.SdITrasmissioneFile")]
public interface SdITrasmissioneFile
{
	[XmlSerializerFormat(SupportFaults = true)]
	[OperationContract(Action = "http://ivaservizi.agenziaentrate.gov.it/SdITrasmissioneFile/Trasmetti", ReplyAction = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0/SdITrasmissioneFile/TrasmettiResponse")]
	TrasmettiResponse Trasmetti(TrasmettiRequest request);

	[OperationContract(Action = "http://ivaservizi.agenziaentrate.gov.it/SdITrasmissioneFile/Trasmetti", ReplyAction = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0/SdITrasmissioneFile/TrasmettiResponse")]
	Task<TrasmettiResponse> TrasmettiAsync(TrasmettiRequest request);

	[XmlSerializerFormat(SupportFaults = true)]
	[OperationContract(Action = "http://ivaservizi.agenziaentrate.gov.it/SdITrasmissioneFile/Esito", ReplyAction = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0/SdITrasmissioneFile/EsitoResponse")]
	EsitoResponse Esito(EsitoRequest request);

	[OperationContract(Action = "http://ivaservizi.agenziaentrate.gov.it/SdITrasmissioneFile/Esito", ReplyAction = "http://ivaservizi.agenziaentrate.gov.it/docs/wsdl/trasmissionefile/v2.0/SdITrasmissioneFile/EsitoResponse")]
	Task<EsitoResponse> EsitoAsync(EsitoRequest request);
}
