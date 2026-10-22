using System;

namespace WKISigner;

public class VerificationFailedException : Exception
{
	public VerificationFailedException(string message)
		: base(message)
	{
	}

	public VerificationFailedException(string message, Exception e)
		: base(message, e)
	{
	}
}
