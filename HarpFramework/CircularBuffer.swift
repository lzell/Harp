import Foundation

class CircularBuffer {
    let maxPacketLen = 256
    let numPacketsToHoldOfMaxLength = 2

    let bufLen : Int
    var buf : CFMutableData

    var wi = 0  // write index
    var ri = 0  // read index

    init() {
        // The extra 1 is because we never let the write index catch up to the read
        // index, so imagine that the total buf length is 2, and someone expects a full
        // message to be in there, and they write "ab" only to discover that we assert.
        bufLen = numPacketsToHoldOfMaxLength * maxPacketLen + 1
        buf = CFDataCreateMutable(nil, bufLen)
    }

    func append(data: CFData, len: Int) {
        print("Trying to append data of length: \(len)")
        assert(len <= maxPacketLen, "Trying to append too much data")

        let (n, r) = getIndexAdvanceValues(len, wi)

        assert(ri <= wi || ri > wi+n, "Would overrun read index")
        var partialBuf = [UInt8](count: n, repeatedValue:0)
        CFDataGetBytes(data, CFRangeMake(0, n), &partialBuf)
        CFDataReplaceBytes(buf, CFRangeMake(wi, n), &partialBuf, n)

        if r > 0 {
            assert(r < ri, "Would overrun read index")
            var remainingBuf = [UInt8](count: r, repeatedValue: 0)
            CFDataGetBytes(data, CFRangeMake(n, r), &remainingBuf)
            CFDataReplaceBytes(buf, CFRangeMake(0, r), &remainingBuf, r)
        }

        wi = (wi + n + r) % bufLen
        assert(wi != ri, "Caught up to read index")
    }

    func read(len: Int, shiftIndex: Bool = true) -> CFData {
        let (n, r) = getIndexAdvanceValues(len, ri)
        assert(n + r == len)
        assert(wi < ri || wi >= ri+n, "Read would overrun write index") // Read can catch up to write
        let retBuf = CFDataCreateMutable(nil, len)!
        var partialBuf = [UInt8](count: n, repeatedValue: 0)
        CFDataGetBytes(buf, CFRangeMake(ri, n), &partialBuf)
        CFDataReplaceBytes(retBuf, CFRangeMake(0, n), &partialBuf, n)
        if r > 0 {
            assert(r <= wi, "Read would overrun write index")
            var remainingBuf = [UInt8](count: r, repeatedValue: 0)
            CFDataGetBytes(buf, CFRangeMake(0, r), &remainingBuf)
            CFDataReplaceBytes(retBuf, CFRangeMake(n, r), &remainingBuf, r)
        }
        if shiftIndex {
            ri = (ri + n + r) % bufLen
        }
        return retBuf
    }

    var lengthStored : Int {
        get {
            if wi > ri {
                return wi - ri
            } else if wi < ri {
                return bufLen - ri + wi
            } else {
                return 0
            }
        }
    }

    func peakTail(len: Int) -> CFData? {
        let (n, r) = getIndexAdvanceValues(len, ri)
        if wi < ri || wi >= ri + n {
            if r == 0 || r <= wi {
                return read(len, shiftIndex: false)
            }
        }
        return nil
    }

    private func getIndexAdvanceValues(len: Int, _ index: Int) -> (Int, Int) {
        let slotsAvailable = bufLen - index
        let n = min(len, slotsAvailable)
        let r = max(len - slotsAvailable, 0)
        return (n, r)
    }
}
