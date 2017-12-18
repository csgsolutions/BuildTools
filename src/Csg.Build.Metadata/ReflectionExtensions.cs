using System;
using System.Linq;

namespace System.Reflection
{
    public static class ReflectionExtensions
    {
        public static string GetAssemblyMetadata(this System.Reflection.Assembly assembly, string key)
        {
            var metaType = typeof(AssemblyMetadataAttribute);

            var attributes = assembly.CustomAttributes
                .Where(x => x.Constructor.DeclaringType == metaType)
                .Select(s => s.ConstructorArguments);

            foreach (var attrib in attributes)
            {
                if (attrib[0].Value.ToString().Equals(key))
                {
                    return attrib[1].Value.ToString();
                }
            }

            return null;
        }

        public static string GetCommitRevision(this System.Reflection.Assembly assembly)
        {
            return assembly.GetAssemblyMetadata("CommitRevision");
        }
        
        public static string GetBuildNumber(this System.Reflection.Assembly assembly)
        {
            return assembly.GetAssemblyMetadata("BuildNumber");
        }
                
        public static DateTime? GetBuildDate(this System.Reflection.Assembly assembly)
        {
            var dt = assembly.GetAssemblyMetadata("BuildDate");

            if (string.IsNullOrEmpty(dt))
            {
                return null;
            }

            return DateTime.Parse(dt);
        }
    }
}
