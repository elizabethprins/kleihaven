async function updateMetaTags(url) {
    try {
        const response = await fetch('/metatags.json');
        const metaTags = await response.json();
        const data = metaTags[url] || metaTags["/"] || {};

        const setMetaTag = (property, content) => {
            let tag = document.querySelector(`meta[property="${property}"]`);
            if (!tag) {
                tag = document.createElement('meta');
                tag.setAttribute('property', property);
                document.head.appendChild(tag);
            }
            tag.setAttribute('content', content);
        };

        setMetaTag('og:title', data.og_title || 'Kleihaven');
        setMetaTag('og:description', data.og_description || 'Keramiekcursussen en workshops in Den Oever');
        setMetaTag('og:image', `${window.location.origin}${data.og_image_path || '/assets/ceramic_classroom.jpeg'}`);
        setMetaTag('og:url', `${window.location.origin}${url}`);
    } catch (error) {
        console.error('Error updating meta tags:', error);
    }
}

// Listen to changes from Elm
if (app && app.ports && app.ports.urlChanged) {
    app.ports.urlChanged.subscribe((newUrl) => {
        updateMetaTags(newUrl);
    });
}