using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;

namespace net45
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
