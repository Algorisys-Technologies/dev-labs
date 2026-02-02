async function runQuery() {
    const queryBox = document.getElementById("query");
    const sqlBox = document.getElementById("sql");
    const resultBox = document.getElementById("result");
    const loader = document.getElementById("loader");

    // HARD CHECK: if any element is missing, stop
    if (!queryBox || !sqlBox || !resultBox || !loader) {
        alert("HTML IDs missing. Check index page.");
        return;
    }

    const query = queryBox.value.trim();
    if (!query) return;

    // Reset UI
    sqlBox.innerText = "";
    resultBox.innerHTML = "";
    loader.classList.remove("hidden");

    try {
        const response = await fetch("/query", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ query })
        });

        const data = await response.json();
        console.log("API RESPONSE:", data); // IMPORTANT DEBUG

        // Show SQL
        sqlBox.innerText = data.generated_sql || "No SQL generated";

        // Render result
        renderTable(data);

    } catch (err) {
        resultBox.innerHTML = `<pre>Error: ${err.message}</pre>`;
    } finally {
        loader.classList.add("hidden");
    }
}

function renderTable(data) {
    const container = document.getElementById("result");

    if (data.final_error) {
        container.innerHTML = `<pre>${data.final_error}</pre>`;
        return;
    }

    const finalResult = data.final_result;
    console.log("FINAL RESULT:", finalResult);

    if (
        !finalResult ||
        !Array.isArray(finalResult.rows) ||
        finalResult.rows.length === 0
    ) {
        container.innerHTML = "<p>No results</p>";
        return;
    }

    const columns = finalResult.columns;
    const rows = finalResult.rows;

    let html = "<table><thead><tr>";
    for (const col of columns) {
        html += `<th>${col}</th>`;
    }
    html += "</tr></thead><tbody>";

    for (const row of rows) {
        html += "<tr>";
        for (const col of columns) {
            html += `<td>${row[col] ?? ""}</td>`;
        }
        html += "</tr>";
    }

    html += "</tbody></table>";
    container.innerHTML = html;
}
