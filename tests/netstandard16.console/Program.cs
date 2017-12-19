using System;
using System.Reflection;

namespace console
{
    class Program
    {
        static void Main(string[] args)
        {
            var assy = typeof(classlib.TestClass).Assembly;

            Console.WriteLine($"CommitRevision: {assy.GetCommitRevision()}");
            Console.WriteLine($"BuildNumber: {assy.GetBuildNumber()}");
        }
    }
}
