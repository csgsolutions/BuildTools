using System;
using System.Reflection;

[assembly: AssemblyMetadata("Foo", "Bar")]

namespace netcoreapp
{
    class Program
    {
        static void Main(string[] args)
        {
            var commit = System.Reflection.Assembly.GetExecutingAssembly().GetCommitRevision();
            var build = System.Reflection.Assembly.GetExecutingAssembly().GetBuildNumber();

            Console.WriteLine($"CommitRevision: {commit}");
            Console.WriteLine($"BuildNumber: {build}");
        }
    }
}
