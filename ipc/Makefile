csharp:
	protoc --descriptor_set_out=csharp-net.protobin --include_imports csharp-ast-net.proto
	mono protobuf-csharp-port-0.9.1/Release/ProtoGen.exe csharp-net.protobin

java:
	#protoc --java_out=../CLRIPCClient/src/ clrinfo.proto
