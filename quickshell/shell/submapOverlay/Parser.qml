import QtQuick

ListModel {
    id: bindModel

    // Call this with the raw output of `hyprctl binds`
    function parse(raw, submap) {
        clear()
        const blocks = raw.trim().split(/\n\n+/)

        for (let block of blocks) {
            if (!block.startsWith("bind")) continue

            let modmask = "", key = "", description = "", dispatcher = "", arg = "", submapName = "", catchall = false

            for (let line of block.split("\n")) {
                if (line.startsWith("modmask:")) modmask = line.split(":")[1].trim()
                if (line.startsWith("key:")) key = line.split(":")[1].trim()
                if (line.startsWith("description:")) description = line.split(":")[1].trim()
                if (line.startsWith("dispatcher:")) dispatcher = line.split(":")[1].trim()
                if (line.startsWith("arg:")) arg = line.split(":")[1].trim()
                if (line.startsWith("submap:")) submapName = line.split(":")[1].trim()
                if (line.startsWith("catchall:")) catchall = line.split(":")[1].trim() === "true"
            }

            if (submapName === submap) {
                append({
                    modmask: modmask,
                    key: key,
                    description: description,
                    dispatcher: dispatcher,
                    arg: arg,
                    catchall: catchall
                })
            }
        }
    }
}
