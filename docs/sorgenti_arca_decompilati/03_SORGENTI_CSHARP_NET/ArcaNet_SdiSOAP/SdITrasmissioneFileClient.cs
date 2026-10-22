using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.Threading.Tasks;

namespace ArcaNet.SdiTrasmissioneFile;

[GeneratedCode("System.ServiceModel", "4.0.0.0")]
[DebuggerStepThrough]
public class SdITrasmissioneFileClient : ClientBase<SdITrasmissioneFile>, SdITrasmissioneFile
{
	public SdITrasmissioneFileClient()
	{
	}

	public SdITrasmissioneFileClient(string endpointConfigurationName)
		: base(endpointConfigurationName)
	{
	}

	public SdITrasmissioneFileClient(string endpointConfigurationName, string remoteAddress)
		: base(endpointConfigurationName, remoteAddress)
	{
	}

	public SdITrasmissioneFileClient(string endpointConfigurationName, EndpointAddress remoteAddress)
		: base(endpointConfigurationName, remoteAddress)
	{
	}

	public SdITrasmissioneFileClient(Binding binding, EndpointAddress remoteAddress)
		: base(binding, remoteAddress)
	{
	}

	[EditorBrowsable(EditorBrowsableState.Advanced)]
	TrasmettiResponse SdITrasmissioneFile.Trasmetti(TrasmettiRequest request)
	{
		return base.Channel.Trasmetti(request);
	}

	public RispostaFile_Type Trasmetti(File_Type file)
	{
		TrasmettiRequest trasmettiRequest = new TrasmettiRequest();
		trasmettiRequest.file = file;
		return ((SdITrasmissioneFile)this).Trasmetti(trasmettiRequest).rispostaFile;
	}

	[EditorBrowsable(EditorBrowsableState.Advanced)]
	Task<TrasmettiResponse> SdITrasmissioneFile.TrasmettiAsync(TrasmettiRequest request)
	{
		return base.Channel.TrasmettiAsync(request);
	}

	public Task<TrasmettiResponse> TrasmettiAsync(File_Type file)
	{
		TrasmettiRequest trasmettiRequest = new TrasmettiRequest();
		trasmettiRequest.file = file;
		return ((SdITrasmissioneFile)this).TrasmettiAsync(trasmettiRequest);
	}

	[EditorBrowsable(EditorBrowsableState.Advanced)]
	EsitoResponse SdITrasmissioneFile.Esito(EsitoRequest request)
	{
		return base.Channel.Esito(request);
	}

	public RispostaEsito_Type Esito(Esito_Type esito1)
	{
		EsitoRequest esitoRequest = new EsitoRequest();
		esitoRequest.esito = esito1;
		return ((SdITrasmissioneFile)this).Esito(esitoRequest).rispostaEsito;
	}

	[EditorBrowsable(EditorBrowsableState.Advanced)]
	Task<EsitoResponse> SdITrasmissioneFile.EsitoAsync(EsitoRequest request)
	{
		return base.Channel.EsitoAsync(request);
	}

	public Task<EsitoResponse> EsitoAsync(Esito_Type esito)
	{
		EsitoRequest esitoRequest = new EsitoRequest();
		esitoRequest.esito = esito;
		return ((SdITrasmissioneFile)this).EsitoAsync(esitoRequest);
	}
}
