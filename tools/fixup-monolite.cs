using Mono.Cecil;
using System;
using System.Reflection;

class FixupMonolite
{
	public static bool Fixup(ModuleDefinition module)
	{
		bool changed = false;

		AssemblyNameReference mscorlib_ref = null, System_ref = null;

		foreach (AssemblyNameReference reference in module.AssemblyReferences)
		{
			if (reference.Name == "mscorlib")
				mscorlib_ref = reference;
			else if (reference.Name == "System")
				System_ref = reference;
		}

		if (mscorlib_ref == null || System_ref == null)
			return false;

		foreach (TypeReference typeref in module.GetTypeReferences())
		{
			if (typeref.Scope == mscorlib_ref && typeref.Namespace == "System.Collections.Generic" &&
				(typeref.Name == "Stack`1" || typeref.Name == "Queue`1"))
			{
				typeref.Scope = System_ref;
				changed = true;
			}
		}
		foreach (ExportedType t in module.ExportedTypes)
		{
			if (t.Scope == mscorlib_ref && t.Namespace == "System.Collections.Generic" &&
				(t.Name == "Stack`1" || t.Name == "Queue`1"))
			{
				t.Scope = System_ref;
				changed = true;
			}
		}

		return changed;
	}

	public static bool Fixup(AssemblyDefinition assembly)
	{
		if (assembly.Name.Name == "System")
			return false;

		bool changed = false;
		foreach (ModuleDefinition module in assembly.Modules)
		{
			if (Fixup(module))
			{
				changed = true;
			}
		}

		return changed;
	}

	public static void Main (string[] args)
	{
		ReaderParameters mode = new ReaderParameters();
		mode.ReadWrite = true;

		foreach (string filename in args)
		{
			var assembly = AssemblyDefinition.ReadAssembly(filename, mode);

			if (Fixup(assembly))
			{
				assembly.Write();
			}
		}
	}
}
