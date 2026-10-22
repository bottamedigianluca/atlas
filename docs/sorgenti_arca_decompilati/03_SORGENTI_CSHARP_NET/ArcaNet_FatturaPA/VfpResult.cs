using System.Runtime.CompilerServices;

namespace ArcaNet.FatturaPA4Vfp;

public class VfpResult
{
	[CompilerGenerated]
	private bool a;

	[CompilerGenerated]
	private string b;

	[CompilerGenerated]
	private string c;

	public bool Success
	{
		[CompilerGenerated]
		get
		{
			return a;
		}
		[CompilerGenerated]
		set
		{
			a = value;
		}
	}

	public string Error
	{
		[CompilerGenerated]
		get
		{
			return b;
		}
		[CompilerGenerated]
		set
		{
			b = value;
		}
	}

	public string Result
	{
		[CompilerGenerated]
		get
		{
			return c;
		}
		[CompilerGenerated]
		set
		{
			c = value;
		}
	}
}
