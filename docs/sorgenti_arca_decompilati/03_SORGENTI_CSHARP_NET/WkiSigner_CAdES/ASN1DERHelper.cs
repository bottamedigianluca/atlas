using System;
using System.Collections.Generic;
using System.Security.Cryptography;

namespace WKISigner;

internal static class ASN1DERHelper
{
	internal static int SequenceFirstTagPosition(byte[] data, int sequencePosition)
	{
		if (data[sequencePosition] != 48)
		{
			throw new ASN1DERException("Atteso un tag SEQUENCE alla posizione: " + sequencePosition + ".");
		}
		return TagValueStartPosition(data, sequencePosition);
	}

	internal static int SetFirstTagPosition(byte[] data, int setPosition)
	{
		if (data[setPosition] != 49)
		{
			throw new ASN1DERException("Atteso un tag SET alla posizione: " + setPosition + ".");
		}
		return TagValueStartPosition(data, setPosition);
	}

	internal static int ContextSpecificFirstTagPosition(byte[] data, int contextSpecificPosition, int contextSpecificNumber)
	{
		if (data[contextSpecificPosition] != 160 + contextSpecificNumber)
		{
			return -1;
		}
		return TagValueStartPosition(data, contextSpecificPosition);
	}

	internal static int TagValueStartPosition(byte[] data, int tagPosition)
	{
		return tagPosition + TagValueLenghtBytesCount(data, tagPosition) + 1;
	}

	internal static int NextTagPosition(byte[] data, int currentTagPosition)
	{
		int num = currentTagPosition + TagLength(data, currentTagPosition);
		if (num >= data.Length)
		{
			num = -1;
		}
		return num;
	}

	internal static int TagLength(byte[] data, int tagPosition)
	{
		int num = 2;
		int num2 = TagValueLenghtBytesCount(data, tagPosition);
		if (num2 > 1)
		{
			byte[] array = new byte[num2 - 1];
			for (int i = 1; i <= array.Length; i++)
			{
				array[array.Length - i] = data[tagPosition + 1 + i];
			}
			num += array.Length;
			for (int j = 0; j < array.Length; j++)
			{
				int num3 = 1;
				for (int k = 1; k <= j; k++)
				{
					num3 *= 256;
				}
				num += array[j] * num3;
			}
		}
		else if (data[tagPosition + 1] != 128)
		{
			num += data[tagPosition + 1];
		}
		else if (data[tagPosition + 2] == 4)
		{
			int l = 2;
			try
			{
				for (; data[tagPosition + l] != 0 || data[tagPosition + l + 1] != 0; l++)
				{
				}
			}
			catch (IndexOutOfRangeException)
			{
				throw new ASN1DERException("Fine dei dati inattesa per il tag Octet String alla posizione: " + tagPosition + ".");
			}
			num += l;
		}
		else
		{
			int num4 = tagPosition + 2;
			try
			{
				while (data[num4] != 0 || data[num4 + 1] != 0)
				{
					num4 = NextTagPosition(data, num4);
					if (num4 == -1)
					{
						throw new IndexOutOfRangeException();
					}
				}
			}
			catch (IndexOutOfRangeException)
			{
				throw new ASN1DERException("Fine dei dati inattesa per il tag alla posizione: " + tagPosition + ".");
			}
			num += num4 - tagPosition;
		}
		return num;
	}

	internal static byte[] TagValue(byte[] data, int tagPosition)
	{
		int num = TagValueStartPosition(data, tagPosition);
		int num2 = TagLength(data, tagPosition) - (num - tagPosition);
		if (data[tagPosition + 1] == 128)
		{
			num2 -= 2;
		}
		byte[] array = new byte[num2];
		Array.Copy(data, num, array, 0, num2);
		return array;
	}

	internal static int TagValueLenghtBytesCount(byte[] data, int tagPosition)
	{
		int num = 1;
		if (data[tagPosition + 1] > 127)
		{
			num += data[tagPosition + 1] - 128;
		}
		return num;
	}

	internal static int TagValueLenght(byte[] data, int tagPosition)
	{
		int num = TagLength(data, tagPosition) - (1 + TagValueLenghtBytesCount(data, tagPosition));
		if (data[tagPosition + 1] == 128)
		{
			num -= 2;
		}
		return num;
	}

	internal static byte[] DerValueLength(int valueLength)
	{
		if (valueLength <= 127)
		{
			return new byte[1] { BitConverter.GetBytes(valueLength)[0] };
		}
		List<byte> list = new List<byte>();
		int num = valueLength;
		do
		{
			list.Insert(0, BitConverter.GetBytes(num % 256)[0]);
			num /= 256;
		}
		while (num != 0);
		list.Insert(0, BitConverter.GetBytes(128 + list.Count)[0]);
		return list.ToArray();
	}

	internal static bool IsOID(string oidString, byte[] data, int oidTagPosition)
	{
		byte[] array = CryptoConfig.EncodeOID(oidString);
		for (int i = 0; i < array.Length; i++)
		{
			if (data[oidTagPosition + i] != array[i])
			{
				return false;
			}
		}
		return true;
	}

	internal static bool Equals(byte[] data1, byte[] data2)
	{
		if (data1.Length != data2.Length)
		{
			return false;
		}
		for (int i = 0; i < data1.Length; i++)
		{
			if (data1[i] != data2[i])
			{
				return false;
			}
		}
		return true;
	}
}
