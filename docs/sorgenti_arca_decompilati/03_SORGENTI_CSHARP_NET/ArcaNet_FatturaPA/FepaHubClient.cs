using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using ArcaNet.ARKManager_V4;
using ArcaNet.FatturaPA4Vfp.ServerTypesForAPI;

namespace ArcaNet.FatturaPA4Vfp;

public class FepaHubClient
{
	[CompilerGenerated]
	private sealed class a
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		public string e;

		public byte[] f;

		public bool g;

		internal Task<InvioResult> h()
		{
			return a.a(b, c, d, e, f, g);
		}
	}

	[CompilerGenerated]
	private sealed class b
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		public string e;

		internal Task<List<EsitoResult>> f()
		{
			return a.a(b, c, d, e);
		}
	}

	[CompilerGenerated]
	private sealed class c
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		internal Task<string> e()
		{
			return a.b(b, c, d);
		}
	}

	[CompilerGenerated]
	private sealed class d
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		internal Task<string> e()
		{
			return a.a(b, c, d);
		}
	}

	[CompilerGenerated]
	private sealed class e
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		public ParamsFattureRx e;

		internal Task<string> f()
		{
			return a.a(b, c, d, e);
		}
	}

	[CompilerGenerated]
	private sealed class f
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		public string e;

		public int f;

		internal Task<string> g()
		{
			return a.a(b, c, d, e, f);
		}
	}

	[CompilerGenerated]
	private sealed class g
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		internal Task<string> e()
		{
			return a.c(b, c, d);
		}
	}

	[CompilerGenerated]
	private sealed class h
	{
		public FepaHubClient a;

		public Eula b;

		internal Task<string> c()
		{
			return a.a(b);
		}
	}

	[CompilerGenerated]
	private sealed class i
	{
		public FepaHubClient a;

		public EulaEx b;

		internal Task<string> c()
		{
			return a.a(b);
		}
	}

	[CompilerGenerated]
	private sealed class j
	{
		public FepaHubClient a;

		public string b;

		public string c;

		public string d;

		public int e;

		internal Task<string> f()
		{
			return a.a(b, c, d, e);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct k : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public FepaHubClient c;

		public Eula d;

		private HttpResponseMessage m_e;

		private TaskAwaiter<HttpResponseMessage> f;

		private TaskAwaiter g;

		private TaskAwaiter<string> h;

		private void e()
		{
			int a_ = 5;
			int num = a;
			FepaHubClient fepaHubClient = c;
			string result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_a.PostAsJsonAsync(GetDocTypeOnLTAUserResult4Vfp.b("㱸\u0e7aᅼṾ", a_), d).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						f = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_0099;
				case 0:
					awaiter3 = f;
					f = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_0099;
				case 1:
					awaiter2 = g;
					g = default(TaskAwaiter);
					num = (a = -1);
					goto IL_0104;
				case 2:
					{
						awaiter = h;
						h = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_0104:
					awaiter2.GetResult();
					awaiter = this.m_e.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						h = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_0099:
					result = awaiter3.GetResult();
					this.m_e = result;
					awaiter2 = ThrowOnRestErrors(this.m_e).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						g = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_0104;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_e = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_e = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in e
			this.e();
		}

		[DebuggerHidden]
		private void e(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in e
			this.e(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct l : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public FepaHubClient c;

		public EulaEx d;

		private HttpResponseMessage m_e;

		private TaskAwaiter<HttpResponseMessage> f;

		private TaskAwaiter g;

		private TaskAwaiter<string> h;

		private void e()
		{
			int a_ = 8;
			int num = a;
			FepaHubClient fepaHubClient = c;
			string result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_a.PostAsJsonAsync(GetDocTypeOnLTAUserResult4Vfp.b("㥻\u0b7d\uec7f\ue381ꮃ쎅\uf087", a_), d).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						f = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_0099;
				case 0:
					awaiter3 = f;
					f = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_0099;
				case 1:
					awaiter2 = g;
					g = default(TaskAwaiter);
					num = (a = -1);
					goto IL_0104;
				case 2:
					{
						awaiter = h;
						h = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_0104:
					awaiter2.GetResult();
					awaiter = this.m_e.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						h = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_0099:
					result = awaiter3.GetResult();
					this.m_e = result;
					awaiter2 = ThrowOnRestErrors(this.m_e).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						g = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_0104;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_e = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_e = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in e
			this.e();
		}

		[DebuggerHidden]
		private void e(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in e
			this.e(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct m : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public string c;

		public string d;

		public string e;

		public FepaHubClient f;

		private HttpResponseMessage m_g;

		private TaskAwaiter<string> h;

		private TaskAwaiter<HttpResponseMessage> i;

		private TaskAwaiter j;

		private void g()
		{
			//IL_0080: Unknown result type (might be due to invalid IL or missing references)
			int a_ = 4;
			int num = a;
			FepaHubClient fepaHubClient = f;
			string result3;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				string result2;
				switch (num)
				{
				default:
					awaiter = ((HttpContent)new FormUrlEncodedContent((IEnumerable<KeyValuePair<string, string>>)new Dictionary<string, string>
					{
						{
							GetDocTypeOnLTAUserResult4Vfp.b("ࡷࡹ፻\u1a7d\uef7f\uf681\uf083\ue985", a_),
							c
						},
						{
							GetDocTypeOnLTAUserResult4Vfp.b("ᑷ፹ύ᭽\uee7f\uf881\ue583", a_),
							d
						},
						{
							GetDocTypeOnLTAUserResult4Vfp.b("ࡷ㍹\u0a7bώ", a_),
							e
						}
					})).ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 0);
						h = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					goto IL_00db;
				case 0:
					awaiter = h;
					h = default(TaskAwaiter<string>);
					num = (a = -1);
					goto IL_00db;
				case 1:
					awaiter3 = i;
					i = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_0153;
				case 2:
					awaiter2 = j;
					j = default(TaskAwaiter);
					num = (a = -1);
					goto IL_01c0;
				case 3:
					{
						awaiter = h;
						h = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_0153:
					result = awaiter3.GetResult();
					this.m_g = result;
					awaiter2 = ThrowOnRestErrors(this.m_g).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 2);
						j = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_01c0;
					IL_00db:
					result2 = awaiter.GetResult();
					awaiter3 = fepaHubClient.m_a.GetAsync(GetDocTypeOnLTAUserResult4Vfp.b("㵷\u0f79ၻώ꽿톁\uf083\ue785ﲇﾉﾋ농", a_) + result2).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 1);
						i = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_0153;
					IL_01c0:
					awaiter2.GetResult();
					awaiter = this.m_g.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 3);
						h = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
				}
				result3 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_g = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_g = null;
			b.SetResult(result3);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in g
			this.g();
		}

		[DebuggerHidden]
		private void g(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in g
			this.g(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct n : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public string c;

		public string d;

		public string e;

		public int f;

		public FepaHubClient g;

		private HttpResponseMessage m_h;

		private TaskAwaiter<string> i;

		private TaskAwaiter<HttpResponseMessage> j;

		private TaskAwaiter k;

		private void h()
		{
			//IL_009f: Unknown result type (might be due to invalid IL or missing references)
			int a_ = 10;
			int num = a;
			FepaHubClient fepaHubClient = g;
			string result3;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				string result2;
				switch (num)
				{
				default:
					awaiter = ((HttpContent)new FormUrlEncodedContent((IEnumerable<KeyValuePair<string, string>>)new Dictionary<string, string>
					{
						{
							GetDocTypeOnLTAUserResult4Vfp.b("\u0e7d\uf27f\ued81\ue083\ue985ﲇﺉ\ue38b", a_),
							c
						},
						{
							GetDocTypeOnLTAUserResult4Vfp.b("ች\ue97f\ue181\ue183\ue885\uf287\ueb89", a_),
							d
						},
						{
							GetDocTypeOnLTAUserResult4Vfp.b("ࡽ\ue17f\uee81\ued83\ue285\ue987ﺉ\ue58b\ue18dﺏ톑ﮓ\uf295ﶗ", a_),
							e
						},
						{
							GetDocTypeOnLTAUserResult4Vfp.b("\u177d\ue47f잁\uf183\uea85\ue987", a_),
							f.ToString()
						}
					})).ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 0);
						i = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					goto IL_00fa;
				case 0:
					awaiter = i;
					i = default(TaskAwaiter<string>);
					num = (a = -1);
					goto IL_00fa;
				case 1:
					awaiter3 = j;
					j = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_0177;
				case 2:
					awaiter2 = k;
					k = default(TaskAwaiter);
					num = (a = -1);
					goto IL_01e4;
				case 3:
					{
						awaiter = i;
						i = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_0177:
					result = awaiter3.GetResult();
					this.m_h = result;
					awaiter2 = ThrowOnRestErrors(this.m_h).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 2);
						k = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_01e4;
					IL_00fa:
					result2 = awaiter.GetResult();
					awaiter3 = fepaHubClient.m_a.PutAsJsonAsync(GetDocTypeOnLTAUserResult4Vfp.b("㭽\uf57f\uee81\ue583ꦅ\ude87\ueb89\ue08b\ue78d\uf48f\uf391\ue093\uf395ꞗ", a_) + result2, "").GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 1);
						j = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_0177;
					IL_01e4:
					awaiter2.GetResult();
					awaiter = this.m_h.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 3);
						i = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
				}
				result3 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_h = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_h = null;
			b.SetResult(result3);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in h
			this.h();
		}

		[DebuggerHidden]
		private void h(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in h
			this.h(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct o : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<List<EsitoResult>> b;

		public FepaHubClient c;

		public string d;

		public string e;

		public string f;

		public string g;

		private HttpResponseMessage m_h;

		private TaskAwaiter<HttpResponseMessage> i;

		private TaskAwaiter j;

		private TaskAwaiter<List<EsitoResult>> k;

		private void h()
		{
			int a_ = 18;
			int num = a;
			FepaHubClient fepaHubClient = c;
			List<EsitoResult> result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<List<EsitoResult>> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_a.GetAsync(GetDocTypeOnLTAUserResult4Vfp.b("삅\ue987ﺉ\uf88bﮍ\ue28f\uf791햓\ue295\uec97\uf399\uea9bﮝ辟\ue7a1힣쾥\udca7쎩莫\ud8ad芯鶱", a_) + d.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("ꦅ", a_) + e.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("ꦅ", a_) + f.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("ꦅ", a_) + g.Trim()).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						i = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_010c;
				case 0:
					awaiter3 = i;
					i = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_010c;
				case 1:
					awaiter2 = j;
					j = default(TaskAwaiter);
					num = (a = -1);
					goto IL_0177;
				case 2:
					{
						awaiter = k;
						k = default(TaskAwaiter<List<EsitoResult>>);
						num = (a = -1);
						break;
					}
					IL_0177:
					awaiter2.GetResult();
					awaiter = this.m_h.Content.ReadAsAsync<List<EsitoResult>>().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						k = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_010c:
					result = awaiter3.GetResult();
					this.m_h = result;
					awaiter2 = ThrowOnRestErrors(this.m_h).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						j = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_0177;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_h = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_h = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in h
			this.h();
		}

		[DebuggerHidden]
		private void h(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in h
			this.h(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct p : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<InvioResult> b;

		public string c;

		public string d;

		public string e;

		public string f;

		public bool g;

		public byte[] h;

		public FepaHubClient i;

		private ByteArrayContent m_j;

		private HttpResponseMessage k;

		private TaskAwaiter<HttpResponseMessage> l;

		private TaskAwaiter m;

		private TaskAwaiter<InvioResult> n;

		private void j()
		{
			//IL_00ce: Unknown result type (might be due to invalid IL or missing references)
			//IL_00d8: Expected O, but got Unknown
			int a_ = 10;
			int num = a;
			FepaHubClient fepaHubClient = i;
			InvioResult result2;
			try
			{
				string text = default(string);
				if ((uint)num > 2u)
				{
					text = GetDocTypeOnLTAUserResult4Vfp.b("㡽\ue17f\uf681\uf083\uf385慎\uef89춋揄\ue48fﮑ\ue293\uf395랗\uec99꺛놝", a_) + c.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("兽", a_) + d.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("兽", a_) + e.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("兽", a_) + f.Trim() + (g ? GetDocTypeOnLTAUserResult4Vfp.b("兽셿\uf281\uf483\uea85\uf187\ud989\ue58b\ue98dﺏ", a_) : string.Empty);
					this.m_j = new ByteArrayContent(h);
				}
				try
				{
					TaskAwaiter<HttpResponseMessage> awaiter;
					if (num != 0)
					{
						if ((uint)(num - 1) <= 1u)
						{
							goto IL_0157;
						}
						awaiter = fepaHubClient.m_a.PostAsync(text, (HttpContent)(object)this.m_j).GetAwaiter();
						if (!awaiter.IsCompleted)
						{
							num = (a = 0);
							l = awaiter;
							b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
							return;
						}
					}
					else
					{
						awaiter = l;
						l = default(TaskAwaiter<HttpResponseMessage>);
						num = (a = -1);
					}
					HttpResponseMessage result = awaiter.GetResult();
					k = result;
					goto IL_0157;
					IL_0157:
					try
					{
						TaskAwaiter<InvioResult> awaiter2;
						TaskAwaiter awaiter3;
						if (num != 1)
						{
							if (num == 2)
							{
								awaiter2 = n;
								n = default(TaskAwaiter<InvioResult>);
								num = (a = -1);
								goto IL_0226;
							}
							awaiter3 = ThrowOnRestErrors(k).GetAwaiter();
							if (!awaiter3.IsCompleted)
							{
								num = (a = 1);
								m = awaiter3;
								b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
								return;
							}
						}
						else
						{
							awaiter3 = m;
							m = default(TaskAwaiter);
							num = (a = -1);
						}
						awaiter3.GetResult();
						awaiter2 = k.Content.ReadAsAsync<InvioResult>().GetAwaiter();
						if (!awaiter2.IsCompleted)
						{
							num = (a = 2);
							n = awaiter2;
							b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
							return;
						}
						goto IL_0226;
						IL_0226:
						result2 = awaiter2.GetResult();
					}
					finally
					{
						if (num < 0 && k != null)
						{
							((IDisposable)k).Dispose();
						}
					}
				}
				finally
				{
					if (num < 0 && this.m_j != null)
					{
						((IDisposable)this.m_j).Dispose();
					}
				}
			}
			catch (Exception exception)
			{
				a = -2;
				b.SetException(exception);
				return;
			}
			a = -2;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in j
			this.j();
		}

		[DebuggerHidden]
		private void j(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in j
			this.j(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct q : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public FepaHubClient c;

		public string d;

		public string e;

		public string f;

		public ParamsFattureRx g;

		private HttpResponseMessage m_h;

		private TaskAwaiter<HttpResponseMessage> i;

		private TaskAwaiter j;

		private TaskAwaiter<string> k;

		private void h()
		{
			int a_ = 8;
			int num = a;
			FepaHubClient fepaHubClient = c;
			string result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_a.PostAsJsonAsync(GetDocTypeOnLTAUserResult4Vfp.b("㩻ώ\uf47f\uf681\uf183\uf485\ued87\uda89\ued8bﶍ\ue38fﮑ\ue293\uf395랗횙\uf59b\ued9d풟쎡讣킥骧薩", a_) + d.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("卻", a_) + e.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("卻", a_) + f.Trim(), g).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						i = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_00f3;
				case 0:
					awaiter3 = i;
					i = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_00f3;
				case 1:
					awaiter2 = j;
					j = default(TaskAwaiter);
					num = (a = -1);
					goto IL_015e;
				case 2:
					{
						awaiter = k;
						k = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_015e:
					awaiter2.GetResult();
					awaiter = this.m_h.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						k = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_00f3:
					result = awaiter3.GetResult();
					this.m_h = result;
					awaiter2 = ThrowOnRestErrors(this.m_h).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						j = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_015e;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_h = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_h = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in h
			this.h();
		}

		[DebuggerHidden]
		private void h(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in h
			this.h(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct r : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public FepaHubClient c;

		public string d;

		public string e;

		public string f;

		public string g;

		public int h;

		private HttpResponseMessage m_i;

		private TaskAwaiter<HttpResponseMessage> j;

		private TaskAwaiter k;

		private TaskAwaiter<string> l;

		private void i()
		{
			int a_ = 18;
			int num = a;
			FepaHubClient fepaHubClient = c;
			string result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_a.GetAsync(GetDocTypeOnLTAUserResult4Vfp.b("삅\ue987ﺉ\uf88bﮍ\ue28f\uf791쒓\uf795\ueb97\ue999\uf59b\ue89d얟趡튣钥螧", a_) + d.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("ꦅ", a_) + e.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("ꦅ", a_) + f.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("ꦅ", a_) + g.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("ꦅ", a_) + h).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						j = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_012d;
				case 0:
					awaiter3 = j;
					j = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_012d;
				case 1:
					awaiter2 = k;
					k = default(TaskAwaiter);
					num = (a = -1);
					goto IL_0198;
				case 2:
					{
						awaiter = l;
						l = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_0198:
					awaiter2.GetResult();
					awaiter = this.m_i.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						l = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_012d:
					result = awaiter3.GetResult();
					this.m_i = result;
					awaiter2 = ThrowOnRestErrors(this.m_i).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						k = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_0198;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_i = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_i = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in i
			this.i();
		}

		[DebuggerHidden]
		private void i(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in i
			this.i(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct s : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public FepaHubClient c;

		public string d;

		public string e;

		public string f;

		private HttpResponseMessage m_g;

		private TaskAwaiter<HttpResponseMessage> h;

		private TaskAwaiter i;

		private TaskAwaiter<string> j;

		private void g()
		{
			int a_ = 0;
			int num = a;
			FepaHubClient fepaHubClient = c;
			string result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_a.GetAsync(GetDocTypeOnLTAUserResult4Vfp.b("㉳\u1775౷\u0e79ॻ౽\ue57f쎁\uf083\uf285\ue187ﲉ\ue98bꆍ횏ﮑ\uf893\uf395\ude97ﮙ\ue89b\uea9d햟킡얣\ue0a5\udaa7얩솫\ue7ad풯\uf4b1햳습첷쾹캻\udfbd邿냁ꯃꋅ\ue7c7볉\uf8cb\ue1cd", a_) + d.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("孳", a_) + e.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("孳", a_) + f.Trim()).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						h = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_00ed;
				case 0:
					awaiter3 = h;
					h = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_00ed;
				case 1:
					awaiter2 = i;
					i = default(TaskAwaiter);
					num = (a = -1);
					goto IL_0158;
				case 2:
					{
						awaiter = j;
						j = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_0158:
					awaiter2.GetResult();
					awaiter = this.m_g.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						j = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_00ed:
					result = awaiter3.GetResult();
					this.m_g = result;
					awaiter2 = ThrowOnRestErrors(this.m_g).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						i = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_0158;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_g = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_g = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in g
			this.g();
		}

		[DebuggerHidden]
		private void g(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in g
			this.g(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct t : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public FepaHubClient c;

		private HttpResponseMessage m_d;

		private TaskAwaiter<HttpResponseMessage> e;

		private TaskAwaiter f;

		private TaskAwaiter<string> g;

		private void d()
		{
			int a_ = 4;
			int num = a;
			FepaHubClient fepaHubClient = c;
			string result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_b.GetAsync(GetDocTypeOnLTAUserResult4Vfp.b("ぷόᵻች\uf47f\uea81잃\uee85\ued87\ue989\ue78b농", a_)).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						e = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_0093;
				case 0:
					awaiter3 = e;
					e = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_0093;
				case 1:
					awaiter2 = f;
					f = default(TaskAwaiter);
					num = (a = -1);
					goto IL_00fe;
				case 2:
					{
						awaiter = g;
						g = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_00fe:
					awaiter2.GetResult();
					awaiter = this.m_d.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						g = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_0093:
					result = awaiter3.GetResult();
					this.m_d = result;
					awaiter2 = ThrowOnRestErrors(this.m_d).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						f = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_00fe;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_d = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_d = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in d
			this.d();
		}

		[DebuggerHidden]
		private void d(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in d
			this.d(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct u : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder<string> b;

		public FepaHubClient c;

		public string d;

		public string e;

		public string f;

		private HttpResponseMessage m_g;

		private TaskAwaiter<HttpResponseMessage> h;

		private TaskAwaiter i;

		private TaskAwaiter<string> j;

		private void g()
		{
			int a_ = 8;
			int num = a;
			FepaHubClient fepaHubClient = c;
			string result2;
			try
			{
				TaskAwaiter<HttpResponseMessage> awaiter3;
				TaskAwaiter awaiter2;
				TaskAwaiter<string> awaiter;
				HttpResponseMessage result;
				switch (num)
				{
				default:
					awaiter3 = fepaHubClient.m_a.GetAsync(GetDocTypeOnLTAUserResult4Vfp.b("㩻ώ\uf47f\uf681\uf183\uf485\ued87쮉\uf88b揄憐\ue491\uf193릕쮗蓮ﶛ\uec9d즟송얣\ue0a5즧\udea9\ud8ab\udbad슯펱鮳", a_) + d.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("卻", a_) + e.Trim() + GetDocTypeOnLTAUserResult4Vfp.b("卻", a_) + f.Trim()).GetAwaiter();
					if (!awaiter3.IsCompleted)
					{
						num = (a = 0);
						h = awaiter3;
						b.AwaitUnsafeOnCompleted(ref awaiter3, ref this);
						return;
					}
					goto IL_00ed;
				case 0:
					awaiter3 = h;
					h = default(TaskAwaiter<HttpResponseMessage>);
					num = (a = -1);
					goto IL_00ed;
				case 1:
					awaiter2 = i;
					i = default(TaskAwaiter);
					num = (a = -1);
					goto IL_0158;
				case 2:
					{
						awaiter = j;
						j = default(TaskAwaiter<string>);
						num = (a = -1);
						break;
					}
					IL_0158:
					awaiter2.GetResult();
					awaiter = this.m_g.Content.ReadAsStringAsync().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 2);
						j = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					break;
					IL_00ed:
					result = awaiter3.GetResult();
					this.m_g = result;
					awaiter2 = ThrowOnRestErrors(this.m_g).GetAwaiter();
					if (!awaiter2.IsCompleted)
					{
						num = (a = 1);
						i = awaiter2;
						b.AwaitUnsafeOnCompleted(ref awaiter2, ref this);
						return;
					}
					goto IL_0158;
				}
				result2 = awaiter.GetResult();
			}
			catch (Exception exception)
			{
				a = -2;
				this.m_g = null;
				b.SetException(exception);
				return;
			}
			a = -2;
			this.m_g = null;
			b.SetResult(result2);
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in g
			this.g();
		}

		[DebuggerHidden]
		private void g(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in g
			this.g(A_0);
		}
	}

	[StructLayout(LayoutKind.Auto)]
	[CompilerGenerated]
	private struct v : IAsyncStateMachine
	{
		public int a;

		public AsyncTaskMethodBuilder b;

		public HttpResponseMessage c;

		private TaskAwaiter<RestError> m_d;

		private void d()
		{
			int a_ = 1;
			int num = a;
			try
			{
				TaskAwaiter<RestError> awaiter;
				if (num == 0)
				{
					awaiter = this.m_d;
					this.m_d = default(TaskAwaiter<RestError>);
					num = (a = -1);
					goto IL_0081;
				}
				if (!c.IsSuccessStatusCode)
				{
					awaiter = c.Content.ReadAsAsync<RestError>().GetAwaiter();
					if (!awaiter.IsCompleted)
					{
						num = (a = 0);
						this.m_d = awaiter;
						b.AwaitUnsafeOnCompleted(ref awaiter, ref this);
						return;
					}
					goto IL_0081;
				}
				goto end_IL_0010;
				IL_0081:
				RestError result = awaiter.GetResult();
				if (result == null)
				{
					if (c.StatusCode == HttpStatusCode.ServiceUnavailable)
					{
						throw new Exception(GetDocTypeOnLTAUserResult4Vfp.b("♴ቶ\u0b78ൺᑼվ\ue880\uec82ꖄ\uf386\uec88\ue68aﶌ\ue08e\ue390\uf292ﮔ\uf296\uf898\uf69a\uf89c\uf19e햠욢薤즦욨얪趬쮮\ud8b0삲어\ud8b6ힸ튺\udfbc횾귀ꛂ", a_));
					}
					throw new Exception(string.Format(GetDocTypeOnLTAUserResult4Vfp.b("㹴㡶䍸孺ټ佾ﲀꎂꢄꞆ\uf288몊\uf08c", a_), c.StatusCode, c.ReasonPhrase));
				}
				switch (c.StatusCode)
				{
				case HttpStatusCode.InternalServerError:
					throw new Exception(string.Format(GetDocTypeOnLTAUserResult4Vfp.b("\u0e74䝶Ѹ孺偼彾婢늂\uf884Ꞇꒈꮊ\uf68c붎\uec90뎒\uee94꒖\ue498", a_), (int)c.StatusCode, result.Message, result.ExceptionType, result.ExceptionMessage));
				case HttpStatusCode.Forbidden:
					throw new Exception(string.Format(GetDocTypeOnLTAUserResult4Vfp.b("\u0e74䝶Ѹ孺偼彾婢늂\uf884", a_), (int)c.StatusCode, result.Message));
				case HttpStatusCode.BadRequest:
					throw new Exception(string.Format(GetDocTypeOnLTAUserResult4Vfp.b("\u0e74䝶Ѹ孺偼彾婢늂\uf884", a_), (int)c.StatusCode, result.Message));
				default:
					throw new Exception(string.Format(GetDocTypeOnLTAUserResult4Vfp.b("\u0e74䝶Ѹ孺偼彾婢늂\uf884", a_), (int)c.StatusCode, result.Message));
				}
				end_IL_0010:;
			}
			catch (Exception exception)
			{
				a = -2;
				b.SetException(exception);
				return;
			}
			a = -2;
			b.SetResult();
		}

		void IAsyncStateMachine.MoveNext()
		{
			//ILSpy generated this explicit interface implementation from .override directive in d
			this.d();
		}

		[DebuggerHidden]
		private void d(IAsyncStateMachine A_0)
		{
			b.SetStateMachine(A_0);
		}

		void IAsyncStateMachine.SetStateMachine(IAsyncStateMachine A_0)
		{
			//ILSpy generated this explicit interface implementation from .override directive in d
			this.d(A_0);
		}
	}

	private readonly HttpClient m_a;

	private readonly HttpClient m_b;

	public FepaHubClient(Action<HttpClient> setupAction = null, byte[] clientCert = null, string clientPwd = null)
	{
		//IL_003c: Unknown result type (might be due to invalid IL or missing references)
		//IL_0046: Expected O, but got Unknown
		//IL_0013: Unknown result type (might be due to invalid IL or missing references)
		//IL_001d: Expected O, but got Unknown
		//IL_0097: Unknown result type (might be due to invalid IL or missing references)
		//IL_00a1: Expected O, but got Unknown
		//IL_00d1: Unknown result type (might be due to invalid IL or missing references)
		//IL_00db: Expected O, but got Unknown
		//IL_00a5: Unknown result type (might be due to invalid IL or missing references)
		//IL_00af: Expected O, but got Unknown
		//IL_0179: Unknown result type (might be due to invalid IL or missing references)
		//IL_0183: Expected O, but got Unknown
		int a_ = 15;
		base._002Ector();
		if (clientCert == null)
		{
			this.m_a = new HttpClient();
		}
		else
		{
			X509Certificate2 value = new X509Certificate2(clientCert, clientPwd);
			this.m_a = new HttpClient((HttpMessageHandler)(object)new WebRequestHandler
			{
				ClientCertificates = { (X509Certificate)value }
			});
		}
		this.m_a.BaseAddress = new Uri(GetDocTypeOnLTAUserResult4Vfp.b("\ueb82\uf184\uf386麗\uf88a람ꂎ뺐\uf292\ue594ﺖﾘﺚ난\ueb9e쒠킢톤覦\udea8쒪솬\udbae풰솲운\udcb6햸캺쪼\udabe돀\uedc2계돆\ue6c8諊鷌蛎ﻐ", a_));
		this.m_a.DefaultRequestHeaders.Accept.Clear();
		this.m_a.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue(GetDocTypeOnLTAUserResult4Vfp.b("\ue282\uf584\uf786\ue588\ue28a\uee8c\uee8e\ue590朗杖練뚘\uf19a\uee9c\uf09e쾠", a_)));
		if (clientCert == null)
		{
			this.m_b = new HttpClient();
		}
		else
		{
			X509Certificate2 value2 = new X509Certificate2(clientCert, clientPwd);
			this.m_b = new HttpClient((HttpMessageHandler)(object)new WebRequestHandler
			{
				ClientCertificates = { (X509Certificate)value2 }
			});
		}
		int result = 3;
		int.TryParse(Environment.GetEnvironmentVariable(GetDocTypeOnLTAUserResult4Vfp.b("슂힄쒆좈풊얌\uda8e펐\udb92킔횖햘쾚햜\udc9e\ue9a0\ue6a2\ue6a4\ueca6\uf6a8ﾪ\ue4ac\ue2ae\uf4b0ﲲ\ue0b4\ue3b6", a_)) ?? string.Format(GetDocTypeOnLTAUserResult4Vfp.b("\uf882떄惘", a_), result), out result);
		this.m_b.Timeout = new TimeSpan(0, 0, result);
		this.m_b.BaseAddress = new Uri(GetDocTypeOnLTAUserResult4Vfp.b("\ueb82\uf184\uf386麗\uf88a람ꂎ뺐\uf292\ue594ﺖﾘﺚ난\ueb9e쒠킢톤覦\udea8쒪솬\udbae풰솲운\udcb6햸캺쪼\udabe돀\uedc2계돆\ue6c8諊鷌蛎ﻐ", a_));
		this.m_b.DefaultRequestHeaders.Accept.Clear();
		this.m_b.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue(GetDocTypeOnLTAUserResult4Vfp.b("\ue282\uf584\uf786\ue588\ue28a\uee8c\uee8e\ue590朗杖練뚘\uf19a\uee9c\uf09e쾠", a_)));
		setupAction?.Invoke(this.m_a);
		setupAction?.Invoke(this.m_b);
	}

	[AsyncStateMachine(typeof(v))]
	protected static Task ThrowOnRestErrors(HttpResponseMessage response)
	{
		v stateMachine = default(v);
		stateMachine.b = AsyncTaskMethodBuilder.Create();
		stateMachine.c = response;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	public string EulaStatus4Vfp(string prodotto, string licenza, string pIva)
	{
		Task<string> task = Task.Run(() => c(prodotto, licenza, pIva));
		task.Wait();
		return task.Result;
	}

	public string EulaInsert(Eula eula)
	{
		Task<string> task = Task.Run(() => a(eula));
		task.Wait();
		return task.Result;
	}

	public string EulaInsertEx(EulaEx eula)
	{
		Task<string> task = Task.Run(() => a(eula));
		task.Wait();
		return task.Result;
	}

	public string EulaValidate4Vfp(string prodotto, string licenza, string otpCode, int idEula)
	{
		Task<string> task = Task.Run(() => a(prodotto, licenza, otpCode, idEula));
		task.Wait();
		return task.Result;
	}

	[AsyncStateMachine(typeof(k))]
	private Task<string> a(Eula A_0)
	{
		k stateMachine = default(k);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.c = this;
		stateMachine.d = A_0;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[AsyncStateMachine(typeof(l))]
	private Task<string> a(EulaEx A_0)
	{
		l stateMachine = default(l);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.c = this;
		stateMachine.d = A_0;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[AsyncStateMachine(typeof(n))]
	private Task<string> a(string A_0, string A_1, string A_2, int A_3)
	{
		n stateMachine = default(n);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.g = this;
		stateMachine.c = A_0;
		stateMachine.d = A_1;
		stateMachine.e = A_2;
		stateMachine.f = A_3;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[AsyncStateMachine(typeof(m))]
	private Task<string> c(string prodotto, string licenza, string pIva)
	{
		m stateMachine = default(m);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.f = this;
		stateMachine.c = prodotto;
		stateMachine.d = licenza;
		stateMachine.e = pIva;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	public InvioResult FattureAttiveInvio(string prodotto, string licenza, string idFatturaProd, string formatoFile, byte[] content, bool applySign)
	{
		Task<InvioResult> task = Task.Run(() => a(prodotto, licenza, idFatturaProd, formatoFile, content, applySign));
		task.Wait();
		return task.Result;
	}

	public List<EsitoResult> FattureAttiveEsiti(string prodotto, string licenza, string idFatturaProd, string progressivoOrNomeFile)
	{
		Task<List<EsitoResult>> task = Task.Run(() => a(prodotto, licenza, idFatturaProd, progressivoOrNomeFile));
		task.Wait();
		return task.Result;
	}

	public string FileFatturaFromIdFatturaProdv4_4Vfp(string prodotto, string licenza, string idFatturaProd)
	{
		Task<string> task = Task.Run(() => b(prodotto, licenza, idFatturaProd));
		task.Wait();
		return task.Result;
	}

	public string ScaricaFatturaAttiva_4Vfp(string prodotto, string licenza, string nomeFileFattura)
	{
		Task<string> task = Task.Run(() => a(prodotto, licenza, nomeFileFattura));
		task.Wait();
		return task.Result;
	}

	[AsyncStateMachine(typeof(p))]
	private Task<InvioResult> a(string A_0, string A_1, string A_2, string A_3, byte[] A_4, bool A_5)
	{
		p stateMachine = default(p);
		stateMachine.b = AsyncTaskMethodBuilder<InvioResult>.Create();
		stateMachine.i = this;
		stateMachine.c = A_0;
		stateMachine.d = A_1;
		stateMachine.e = A_2;
		stateMachine.f = A_3;
		stateMachine.h = A_4;
		stateMachine.g = A_5;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[AsyncStateMachine(typeof(o))]
	private Task<List<EsitoResult>> a(string A_0, string A_1, string A_2, string A_3)
	{
		o stateMachine = default(o);
		stateMachine.b = AsyncTaskMethodBuilder<List<EsitoResult>>.Create();
		stateMachine.c = this;
		stateMachine.d = A_0;
		stateMachine.e = A_1;
		stateMachine.f = A_2;
		stateMachine.g = A_3;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[AsyncStateMachine(typeof(s))]
	private Task<string> b(string prodotto, string licenza, string idFatturaProd)
	{
		s stateMachine = default(s);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.c = this;
		stateMachine.d = prodotto;
		stateMachine.e = licenza;
		stateMachine.f = idFatturaProd;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[AsyncStateMachine(typeof(u))]
	private Task<string> a(string prodotto, string licenza, string nomeFileFattura)
	{
		u stateMachine = default(u);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.c = this;
		stateMachine.d = prodotto;
		stateMachine.e = licenza;
		stateMachine.f = nomeFileFattura;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	public string FatturePassiveLista4Vfp(string prodotto, string licenza, string codiceDestinatario, ParamsFattureRx parametri)
	{
		Task<string> task = Task.Run(() => a(prodotto, licenza, codiceDestinatario, parametri));
		task.Wait();
		return task.Result;
	}

	public string FatturePassiveRicevi4Vfp(string prodotto, string licenza, string codiceDestinatario, string partitaIva, int idFatturaRx)
	{
		Task<string> task = Task.Run(() => a(prodotto, licenza, codiceDestinatario, partitaIva, idFatturaRx));
		task.Wait();
		return task.Result;
	}

	[AsyncStateMachine(typeof(q))]
	private Task<string> a(string A_0, string A_1, string A_2, ParamsFattureRx A_3)
	{
		q stateMachine = default(q);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.c = this;
		stateMachine.d = A_0;
		stateMachine.e = A_1;
		stateMachine.f = A_2;
		stateMachine.g = A_3;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[AsyncStateMachine(typeof(r))]
	private Task<string> a(string A_0, string A_1, string A_2, string A_3, int A_4)
	{
		r stateMachine = default(r);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.c = this;
		stateMachine.d = A_0;
		stateMachine.e = A_1;
		stateMachine.f = A_2;
		stateMachine.g = A_3;
		stateMachine.h = A_4;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	public string HealthCheck4Vfp()
	{
		Task<string> task = Task.Run(() => b());
		task.Wait();
		return task.Result;
	}

	[AsyncStateMachine(typeof(t))]
	private Task<string> b()
	{
		t stateMachine = default(t);
		stateMachine.b = AsyncTaskMethodBuilder<string>.Create();
		stateMachine.c = this;
		stateMachine.a = -1;
		stateMachine.b.Start(ref stateMachine);
		return stateMachine.b.Task;
	}

	[CompilerGenerated]
	private Task<string> a()
	{
		return b();
	}
}
