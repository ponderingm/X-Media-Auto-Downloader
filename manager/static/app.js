document.addEventListener('DOMContentLoaded', () => {
    const urlsEditor = document.getElementById('urls-editor');
    const saveBtn = document.getElementById('save-btn');
    const logsViewer = document.getElementById('logs-viewer');
    const refreshLogsBtn = document.getElementById('refresh-logs-btn');

    // Load URLs
    async function loadUrls() {
        try {
            const response = await fetch('/api/urls');
            const data = await response.json();
            urlsEditor.value = data.content;
        } catch (error) {
            console.error('Error loading URLs:', error);
            alert('Failed to load URLs');
        }
    }

    // Save URLs
    async function saveUrls() {
        const content = urlsEditor.value;
        const originalText = saveBtn.innerText;
        saveBtn.innerText = 'Saving...';
        saveBtn.disabled = true;

        try {
            const response = await fetch('/api/urls', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ content }),
            });

            if (response.ok) {
                saveBtn.innerText = 'Saved!';
                setTimeout(() => {
                    saveBtn.innerText = originalText;
                    saveBtn.disabled = false;
                }, 2000);
            } else {
                throw new Error('Failed to save');
            }
        } catch (error) {
            console.error('Error saving URLs:', error);
            alert('Failed to save URLs');
            saveBtn.innerText = originalText;
            saveBtn.disabled = false;
        }
    }

    // Load Logs
    async function loadLogs() {
        try {
            const response = await fetch('/api/logs');
            const data = await response.json();
            logsViewer.textContent = data.logs;
            // Scroll to bottom
            logsViewer.scrollTop = logsViewer.scrollHeight;
        } catch (error) {
            console.error('Error loading logs:', error);
            logsViewer.textContent = 'Failed to load logs.';
        }
    }

    // Event Listeners
    saveBtn.addEventListener('click', saveUrls);
    refreshLogsBtn.addEventListener('click', loadLogs);

    // Initial Load
    loadUrls();
    loadLogs();

    // Auto-refresh logs every 10 seconds
    setInterval(loadLogs, 10000);
});
