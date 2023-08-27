#let _int-to-bits(int, length: -1) = {
    let bits = ()
    let count = 0
    while int > 0 or (length != -1 and count < length) {
        bits.push(if calc.even(int) { 0 } else { 1 })
        int = calc.floor(int / 2)
        count += 1
    }
    return bits.rev()
}
#let _bits-to-int(bits) = {
    let result = 0
    for bit in bits {
        result *= 2
        result += bit
    }
    return result
}
#let _base64-decode(str) = {
    let base64-chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    let base64-ids = (:)
    for (i, c) in base64-chars.clusters().enumerate() {
        base64-ids.insert(c, i)
    }
    base64-ids.insert("=", "=")

    let values = str.clusters().map(it => base64-ids.at(it))
    let bytes-array = ()
    for i in range(values.len(), step: 4) {
        let aggregate = ()
        for j in range(4) {
            let value = values.at(i + j)
            if value == "=" {
                break
            }
            let bits = _int-to-bits(value, length: 6)
            aggregate += bits
        }
        for j in range(calc.floor(aggregate.len() / 8)) {
            bytes-array.push(_bits-to-int(aggregate.slice(j * 8, j * 8 + 8)))
        }
    }
    return bytes(bytes-array)
}
#let _render-notebook(label) = {
    let number = counter(<typst-notebook>).at(label.location())
    if number == (0,) { return } // Typst Bug
    let contents = json(".typst-notebook/output-" + str(number.join(".")) + ".json")
    for content in contents {
        if "image/svg" in content {
            image.decode(content.at("image/svg"), format: "svg")
        } else if "image/png" in content {
            image.decode(_base64-decode(content.at("image/png")), format: "png", width: 80%)
        } else if "image/jpg" in content {
            image.decode(content.at("image/jpg"), format: "jpg")
        } else if "image/gif" in content {
            image.decode(content.at("image/gif"), format: "gif")
        } else if "text/plain" in content {
            eval("[" + content.at("text/plain") + "]")
        } else {
            [No supportet mime-type found]
        }
    }
}

#let notebook-render(show-code: true, caption: none, body) = {
    show <typst-notebook>: _render-notebook

    if show-code { body }
    figure(caption: caption)[
        #body <typst-notebook>
    ]
}
