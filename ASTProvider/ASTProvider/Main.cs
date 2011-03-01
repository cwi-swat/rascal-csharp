using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net.Sockets;
using System.Net;
using System.IO;
using Landman.Rascal.CSharp.Profobuf;
using Google.ProtocolBuffers;
using ICSharpCode.NRefactory.CSharp;


namespace Landman.Rascal.CSharp.ASTProvider
{
	partial class MainClass
	{
		static partial void GenerateNode(ICSharpCode.NRefactory.CSharp.AstNode root, Landman.Rascal.CSharp.Profobuf.AstNode.Builder result);
		
		public static void Main (string[] args)
		{
			var server = new TcpListener(IPAddress.Loopback, 5556);
			server.Start();
			while (true)
			{
				var newClient = server.AcceptTcpClient();
				Console.WriteLine("Got new client.");
				using (var clientStream = newClient.GetStream())
				{
					var request = CSharpParseRequest.ParseDelimitedFrom(clientStream);
					Console.WriteLine("Starting collecting AST for:\n");
					Console.WriteLine(request.Filename);
					var parser = new CSharpParser();
					var csFile = new FileStream(request.Filename, FileMode.Open);
					var cu = parser.Parse(csFile);
					var resultBuilder = CSharpParseResult.CreateBuilder();
					foreach (var child in cu.Children) {
						var builder = Landman.Rascal.CSharp.Profobuf.AstNode.CreateBuilder();
						GenerateNode(child, builder);
						resultBuilder.AddResult(builder);
					}
					resultBuilder.Build().WriteDelimitedTo(clientStream);
					Console.WriteLine("\nFinished");
				}

			}

		}
	}
}

