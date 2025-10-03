using System;

public abstract class Comparable<T> : IEquatable<T> where T : Comparable<T>
{
    protected abstract (object?[] Components) GetComparableComponents();

    public bool Equals(T? other)
    {
        if (other is null) return false;
        if (ReferenceEquals(this, other)) return true;

        var left  = GetComparableComponents().Components;
        var right = other.GetComparableComponents().Components;
        if (left.Length != right.Length) return false;

        for (int i = 0; i < left.Length; i++)
            if (!Equals(left[i], right[i])) return false;

        return true;
    }

    public override bool Equals(object? obj) => obj is T vo && Equals(vo);

    public override int GetHashCode()
    {
        unchecked
        {
            int hash = 17;
            foreach (var c in GetComparableComponents().Components)
                hash = (hash * 31) + (c?.GetHashCode() ?? 0);
            return hash;
        }
    }

    public static bool operator ==(Comparable<T>? l, Comparable<T>? r) => Equals(l, r);
    public static bool operator !=(Comparable<T>? l, Comparable<T>? r) => !Equals(l, r);
}

