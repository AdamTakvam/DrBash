using System;

public sealed class VideoSampleHash : Comparable<VideoSampleHash>
{
    public string Head { get; }
    public string Tail { get; }
    public string Algorithm { get; }

    /// <summary>Requested window length in seconds (what the caller asked for).</summary>
    public int RequestedWindowSeconds { get; }

    /// <summary>Actual duration hashed for the head sample, in milliseconds.</summary>
    public int HeadMillisHashed { get; }

    /// <summary>Actual duration hashed for the tail sample, in milliseconds.</summary>
    public int TailMillisHashed { get; }

    public VideoSampleHash(
        string head,
        string tail,
        string algorithm,
        int requestedWindowSeconds,
        int headMillisHashed,
        int tailMillisHashed)
    {
        Head  = head  ?? throw new ArgumentNullException(nameof(head));
        Tail  = tail  ?? throw new ArgumentNullException(nameof(tail));
        Algorithm = algorithm ?? throw new ArgumentNullException(nameof(algorithm));

        if (requestedWindowSeconds <= 0) throw new ArgumentOutOfRangeException(nameof(requestedWindowSeconds));
        if (headMillisHashed < 0) throw new ArgumentOutOfRangeException(nameof(headMillisHashed));
        if (tailMillisHashed < 0) throw new ArgumentOutOfRangeException(nameof(tailMillisHashed));

        RequestedWindowSeconds = requestedWindowSeconds;
        HeadMillisHashed = headMillisHashed;
        TailMillisHashed = tailMillisHashed;
    }

    protected override (object?[] Components) GetComparableComponents() =>
        (new object?[]
        {
            Head, Tail, Algorithm,
            RequestedWindowSeconds,
            HeadMillisHashed,
            TailMillisHashed
        });

    public void Deconstruct(out string head, out string tail, out string alg,
                            out int requestedWindowSeconds, out int headMs, out int tailMs)
    {
        head = Head; tail = Tail; alg = Algorithm;
        requestedWindowSeconds = RequestedWindowSeconds;
        headMs = HeadMillisHashed; tailMs = TailMillisHashed;
    }

    public override string ToString() =>
        $"Head={Head}, Tail={Tail}, Alg={Algorithm}, Win={RequestedWindowSeconds}s, " +
        $"HeadHashed={HeadMillisHashed}ms, TailHashed={TailMillisHashed}ms";
}

