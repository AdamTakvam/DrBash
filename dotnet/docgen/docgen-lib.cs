// dotnet-script usage:
//   dotnet tool install -g dotnet-script  (once)
//   dotnet script docgen-lib.csx ./lib/logging.sh > LOGGING.md

#nullable enable
using System.Text;
using System.Text.RegularExpressions;

if (Args.Length != 1) { Console.Error.WriteLine("Usage: docgen-lib.csx <path-to-bash-lib>"); Environment.Exit(2); }
var path = Args[0];
var lines = File.ReadAllLines(path);

// Function patterns (support common bash styles + brace on next line)
var singleLineFuncs = new[]{
    new Regex(@"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", RegexOptions.Compiled),
    new Regex(@"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*\)\s*\{", RegexOptions.Compiled),
    new Regex(@"^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*\)\s*\{", RegexOptions.Compiled),
    new Regex(@"^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{", RegexOptions.Compiled),
};
var headerThenBrace = new[]{
    new Regex(@"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*\)\s*$", RegexOptions.Compiled),
    new Regex(@"^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*\)\s*$", RegexOptions.Compiled),
    new Regex(@"^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", RegexOptions.Compiled),
};

bool IsComment(string s) => Regex.IsMatch(s, @"^\s*#");
string StripComment(string s) => Regex.Replace(s, @"^\s*#\s?", "");

string? TryMatchFunctionName(int i, out int headerLineIndex)
{
    headerLineIndex = i;

    // Single-line "name() {"
    foreach (var rx in singleLineFuncs)
    {
        var m = rx.Match(lines[i]);
        if (m.Success) return m.Groups[1].Value;
    }

    // Two-line "name()" then "{" on the next line
    foreach (var rx in headerThenBrace)
    {
        var m = rx.Match(lines[i]);
        if (m.Success && i + 1 < lines.Length && Regex.IsMatch(lines[i + 1], @"^\s*\{"))
        {
            return m.Groups[1].Value;
        }
    }

    return null;
}

// Collect all function headers (line index → name)
var funcs = new List<(int headerIdx, string name)>();
for (int i = 0; i < lines.Length; i++)
{
    var name = TryMatchFunctionName(i, out var hdrIdx);
    if (name != null)
    {
        funcs.Add((hdrIdx, name));
        // skip the next line if it is just "{"
        if (i + 1 < lines.Length && Regex.IsMatch(lines[i + 1], @"^\s*\{")) i++;
    }
}

// Build output
var sb = new StringBuilder();
sb.AppendLine("# Function Reference");
sb.AppendLine($"_Source: {path}_");
sb.AppendLine();

foreach (var (hdrIdx, name) in funcs)
{
    // Scan UP from the header for the contiguous block of comments
    var doc = new List<string>();
    int j = hdrIdx - 1;

    // skip leading blank lines immediately above header but preserve if inside comment block
    while (j >= 0 && string.IsNullOrWhiteSpace(lines[j])) j--;

    // collect contiguous comment lines upward
    int first = j;
    while (first >= 0 && IsComment(lines[first])) first--;
    first++; // now points to first comment line of the block

    // Only keep if at least one comment line exists and there is no code line between block and header
    // (We already moved through blanks; by construction, contiguous.)
    if (first <= j && IsComment(lines[j]))
    {
        for (int k = first; k <= j; k++)
            doc.Add(StripComment(lines[k]));
    }

    var priv = name.StartsWith("_") ? " (private)" : "";
    sb.AppendLine($"### {name}{priv}");
    sb.AppendLine();

    if (doc.Count == 0)
        sb.AppendLine("_No doc block above function._");
    else
    {
        foreach (var l in doc) sb.AppendLine(l);
    }
    sb.AppendLine();
}

Console.Write(sb.ToString());

