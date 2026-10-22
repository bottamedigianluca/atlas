using System;

namespace WKISigner;

public class ASN1DERException : Exception
{
	public ASN1DERException(string message)
		: base(message)
	{
	}

	public ASN1DERException(string message, Exception e)
		: base(message, e)
	{
	}
}
