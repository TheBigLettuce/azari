package lol.bruh19.azari.gallery

import android.graphics.Bitmap


// these are written from github.com/corona10/goimagehash impl
// goimagehash is BSD 2-Clause License

internal fun medianOfPixelsFast64(grayscale: List<Double>): Double {
    val tmp = grayscale.toMutableList()
    val pos = tmp.count() / 2

    return quickSelectMedian(tmp, 0, tmp.count() - 1, pos)
}

internal fun quickSelectMedian(sequence: MutableList<Double>, low1: Int, hi1: Int, k: Int): Double {
    if (low1 == hi1) {
        return sequence[k]
    }

    var hi = hi1
    var low = low1
    while (low < hi) {
        val pivot = low / 2 + hi / 2
        val pivotValue = sequence[pivot]
        var storeIndx = low
        var prevhi = sequence[hi]
        val prevpivot = sequence[pivot]
        sequence[pivot] = prevhi
        sequence[hi] = prevpivot

        for (i in low until hi) {
            if (sequence[i] < pivotValue) {
                val previdx = sequence[storeIndx]
                val previ = sequence[i]
                sequence[storeIndx] = previ
                sequence[i] = previdx
                storeIndx++
            }
        }

        prevhi = sequence[hi]
        val previdx = sequence[storeIndx]
        sequence[hi] = previdx
        sequence[storeIndx] = prevhi

        if (k <= storeIndx) {
            hi = storeIndx
        } else {
            low = storeIndx + 1
        }
    }

    if (sequence.count() % 2 == 0) {
        return sequence[k - 1] / 2 + sequence[k] / 2
    }

    return sequence[k]
}

internal fun pixel2Gray(r: Float, g: Float, b: Float): Double {
    return 0.299 * r / 257 + 0.587 * g / 257 + 0.114 * b / 256
}

internal fun rgb2Gray(pixels: Bitmap): MutableList<Double> {
    val ret = MutableList(pixels.height * pixels.width) {
        0.0
    }

    for (i in 0 until 64) {
        for (j in 0 until 64) {
            val color = pixels.getColor(j, i)
            ret[j + (i * 64)] = pixel2Gray(color.red(), color.green(), color.blue())
        }
    }

    return ret
}

internal fun DCT2DFast64(pixels: MutableList<Double>): List<Double> {
    for (i in 0 until 64) {
        forwardDCT64(pixels.subList(i * 64, (i * 64) + 64))
    }

    val row = MutableList(64) { 0.0 }
    val flattens = MutableList(64) { 0.0 }

    for (i in 0 until 8) {
        for (j in 0 until 64) {
            row[j] = pixels[64 * j + i]
        }

        forwardDCT64(row)

        for (j in 0 until 8) {
            flattens[8 * j + i] = row[j]
        }
    }

    return flattens
}


// forwardDCT64 function returns result of DCT-II.
// DCT type II, unscaled. Algorithm by Byeong Gi Lee, 1984.
// Static implementation by Evan Oberholster, 2022.
internal fun forwardDCT64(input: MutableList<Double>) {
    val temp = MutableList(64) { 0.0 }
    for (i in 0 until 32) {
        val (x, y) = Pair(input[i], input[63 - i])
        temp[i] = x + y
        temp[i + 32] = (x - y) / dct64[i]
    }

    forwardDCT32(temp.subList(0, 32))
    forwardDCT32(temp.subList(32, temp.count()))

    for (i in 0 until 32 - 1) {
        input[i * 2 + 0] = temp[i]
        input[i * 2 + 1] = temp[i + 32] + temp[i + 32 + 1]
    }

    input[62] = temp[31]
    input[63] = temp[63]
}

internal fun forwardDCT32(input: MutableList<Double>) {
    val temp = MutableList(32) { 0.0 }
    for (i in 0 until 16) {
        val (x, y) = Pair(input[i], input[31 - i])
        temp[i] = x + y
        temp[i + 16] = (x - y) / dct32[i]
    }

    forwardDCT16(temp.subList(0, 16))
    forwardDCT16(temp.subList(16, temp.count()))

    for (i in 0 until 16 - 1) {
        input[i * 2 + 0] = temp[i]
        input[i * 2 + 1] = temp[i + 16] + temp[i + 16 + 1]
    }

    input[30] = temp[15]
    input[31] = temp[31]
}

internal fun forwardDCT16(input: MutableList<Double>) {
    val temp = MutableList(16) { 0.0 }
    for (i in 0 until 8) {
        val (x, y) = Pair(input[i], input[15 - i])
        temp[i] = x + y
        temp[i + 8] = (x - y) / dct16[i]
    }

    forwardDCT8(temp.subList(0, 8))
    forwardDCT8(temp.subList(8, temp.count()))

    for (i in 0 until 8 - 1) {
        input[i * 2 + 0] = temp[i]
        input[i * 2 + 1] = temp[i + 8] + temp[i + 8 + 1]
    }

    input[14] = temp[7]
    input[15] = temp[15]
}

internal fun forwardDCT8(input: MutableList<Double>) {
    val (a, b) = Pair(Array(4) { 0.0 }, Array(4) { 0.0 })

    val (x0, y0) = Pair(input[0], input[7])
    val (x1, y1) = Pair(input[1], input[6])
    val (x2, y2) = Pair(input[2], input[5])
    val (x3, y3) = Pair(input[3], input[4])

    a[0] = x0 + y0
    a[1] = x1 + y1
    a[2] = x2 + y2
    a[3] = x3 + y3
    b[0] = (x0 - y0) / 1.9615705608064609
    b[1] = (x1 - y1) / 1.6629392246050907
    b[2] = (x2 - y2) / 1.1111404660392046
    b[3] = (x3 - y3) / 0.3901806440322566

    forwardDCT4(a)
    forwardDCT4(b)

    input[0] = a[0]
    input[1] = b[0] + b[1]
    input[2] = a[1]
    input[3] = b[1] + b[2]
    input[4] = a[2]
    input[5] = b[2] + b[3]
    input[6] = a[3]
    input[7] = b[3]
}

internal fun forwardDCT4(input: Array<Double>) {
    val (x0, y0) = Pair(input[0], input[3])
    val (x1, y1) = Pair(input[1], input[2])

    var t0 = x0 + y0
    var t1 = x1 + y1
    var t2 = (x0 - y0) / 1.8477590650225735
    var t3 = (x1 - y1) / 0.7653668647301797

    var (x, y) = Pair(t0, t1)
    t0 += t1
    t1 = (x - y) / 1.4142135623730951

    x = t2
    y = t3

    t2 += t3
    t3 = (x - y) / 1.4142135623730951

    input[0] = t0
    input[1] = t2 + t3
    input[2] = t1
    input[3] = t3
}

val dct64 = listOf(
    1.9993976373924083,
    1.9945809133573804,
    1.9849590691974202,
    1.9705552847778824,
    1.9514042600770571,
    1.9275521315908797,
    1.8990563611860733,
    1.8659855976694777,
    1.8284195114070614,
    1.7864486023910306,
    1.7401739822174227,
    1.6897071304994142,
    1.6351696263031674,
    1.5766928552532127,
    1.5144176930129691,
    1.448494165902934,
    1.3790810894741339,
    1.3063456859075537,
    1.2304631811612539,
    1.151616382835691,
    1.0699952397741948,
    0.9857963844595683,
    0.8992226593092132,
    0.8104826280099796,
    0.7197900730699766,
    0.627363480797783,
    0.5334255149497968,
    0.43820248031373954,
    0.3419237775206027,
    0.24482135039843256,
    0.1471291271993349,
    0.049082457045824535
)


val dct32 = listOf(
    1.9975909124103448,
    1.978353019929562,
    1.9400625063890882,
    1.8830881303660416,
    1.8079785862468867,
    1.7154572200005442,
    1.6064150629612899,
    1.4819022507099182,
    1.3431179096940369,
    1.191398608984867,
    1.0282054883864435,
    0.8551101868605644,
    0.6737797067844401,
    0.48596035980652796,
    0.2934609489107235,
    0.09813534865483627
)

val dct16 = listOf(
    1.9903694533443936,
    1.9138806714644176,
    1.76384252869671,
    1.546020906725474,
    1.2687865683272912,
    0.9427934736519956,
    0.5805693545089246,
    0.19603428065912154
)