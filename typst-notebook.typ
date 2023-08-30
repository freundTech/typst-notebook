#let _notebook-id = state("_notebook-id", none)
#let _kernel = state("_kernel", none)
#let _notebook-data = json(".typst-notebook/output.json")

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

#let _render-vegalite(content) = {
    import "@preview/plotst:0.1.0"

    let data = ()
    for value in content.data.values.slice(1) {
        data.push((float(value.at(content.encoding.x.field)), float(value.at(content.encoding.y.field))))
    }

    let x-axis = if content.encoding.x.type == "quantitative" {
        plotst.axis(min: 0, max: 10, step: 1, title: content.encoding.x.field, location: "bottom", helper_lines: content.config.axis.grid)
    } else { panic("Unsupported") }
    let y-axis = if content.encoding.y.type == "quantitative" {
        plotst.axis(min: 0, max: 100, step: 10, title: content.encoding.y.field, location: "left", helper_lines: content.config.axis.grid)
    } else { panic("Unsupported") }


    let plot = plotst.plot(data: data, axes: (x-axis, y-axis))
    return plotst.scatter_plot(plot, (20%, 20%))
}

#let _notebook-mimetypes = (
    "text/typst": it => eval("[" + it + "]"),
    "application/vnd.vegalite.v3+json": _render-vegalite,
    "image/svg": it => image.decode(_base64-decode(it), format: "svg"),
    "image/png": it => image.decode(_base64-decode(it), format: "png"),
    "image/jpg": it => image.decode(_base64-decode(it), format: "jpg"),
    "image/gif": it => image.decode(_base64-decode(it), format: "gif"),
    "text/raw": it => raw(block: true, it),
    "text/plain": it => it,
)
#let _notebook-mimetype-priorities = (
    "text/typst",
    "application/vnd.vegalite.v3+json",
    "image/svg",
    "image/png",
    "image/jpg",
    "image/gif",
    "text/raw",
    "text/plain",
)

#let _warning(body) = {
    set text(fill: red, weight: "bold")
    body
}

#let _render-display-data(display-data) = {
    for mime-type in _notebook-mimetype-priorities {
        if mime-type in display-data.keys() {
            let handler = _notebook-mimetypes.at(mime-type)
            return handler(display-data.at(mime-type))
        }
    }
    return [No supported mime-type found: #display-data.keys()]
}
#let _render-notebook(label) = {
    let notebook-id = _notebook-id.at(label.location())
    if notebook-id == none {
        return
    }
    let cell-number = counter(<typst-notebook-cell>).at(label.location()).first()

    if cell-number == (0,) { return } // Typst Bug

    let notebook-data = _notebook-data.at(notebook-id, default: ())
    let cell-data = notebook-data.at(cell-number - 1, default: (:))

    if cell-data == (:) {
        return _warning[Missing result data. Please run typst-notebook.]
    }
    for display-data in cell-data.display-data {
        if cell-data.code != label.value.code {
            _warning[Outdated result data. Please run typst-notebook.]
        }
        _render-display-data(display-data)
    }
}

#let notebook-add-mimetype-handler(mime-type, handler) = {
    _notebook-mimetypes.insert(mime-type, handler)
    _notebook-mimetype-priorities.insert(0, mime-type)
    return repr(_notebook-mimetype-priorities)
}

#let notebook(kernel, id: none, body) = {
    show <typst-notebook-cell>: it => {
        let cell-number = counter(<typst-notebook-cell>).at(it.location()).first()

        _render-notebook(it)
    }

    locate(loc => {
        let notebook-id = str(counter(<typst-notebook>).at(loc).first())

        [#metadata(("id": notebook-id, "kernel": kernel))<typst-notebook>]
        counter(<typst-notebook-cell>).update(0)
        let outer-notebook = _notebook-id.at(loc)
        _notebook-id.update(notebook-id)
        body
        _notebook-id.update(outer-notebook)
    })
}

#let notebook-cell(show-code: true, code) = locate(loc => {
    let notebook-id = _notebook-id.at(loc)
    if notebook-id == none {
        panic("notebook-cell() can only be used within a notebook()")
    }
    if show-code { code }

    [#metadata(("code": code.text, "notebook": _notebook-id.at(loc)))<typst-notebook-cell>]
})