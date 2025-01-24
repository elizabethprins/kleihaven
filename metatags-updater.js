async function updateMetaTags(url) {
    try {
        const response = await fetch('/metatags.json');
        const metaTags = await response.json();
        const data = metaTags[url] || metaTags["/"] || {};

        const setTitle = (title) => {
            document.title = title;
        };

        const setDescription = (description) => {
            let tag = document.querySelector('meta[name="description"]');
            if (!tag) {
                tag = document.createElement('meta');
                tag.setAttribute('name', 'description');
                document.head.appendChild(tag);
            }
            tag.setAttribute('content', description);
        };

        const setMetaTag = (property, content) => {
            let tag = document.querySelector(`meta[property="${property}"]`);
            if (!tag) {
                tag = document.createElement('meta');
                tag.setAttribute('property', property);
                document.head.appendChild(tag);
            }
            tag.setAttribute('content', content);
        };

        const setCanonicalLink = (url) => {
            let link = document.querySelector('link[rel="canonical"]');
            if (!link) {
                link = document.createElement('link');
                link.rel = 'canonical';
                document.head.appendChild(link);
            }
            link.href = url;
        };

        const baseUrl = window.env?.BASE_URL || window.location.origin;
        const parsedUrl = new URL(url, baseUrl);
        const fullUrl = parsedUrl.origin + parsedUrl.pathname;

        setTitle(data.og_title || 'Studio1931 | Kleihaven');
        setDescription(data.og_description || 'Keramiekcursussen en artist residency in Den Oever');
        setMetaTag('og:title', data.og_title || 'Studio1931 | Kleihaven');
        setMetaTag('og:description', data.og_description || 'Keramiekcursussen en artist residency in Den Oever');
        setMetaTag('og:image', `${baseUrl}${data.og_image_path || '/assets/og-images/buitencursus.jpg'}`);
        setMetaTag('og:image:alt', data.og_image_alt || 'Cursisten aan het werk in de tuin van de school');
        setMetaTag('og:image:width', data.og_image_width || '1200');
        setMetaTag('og:image:height', data.og_image_height || '630');
        setMetaTag('og:url', fullUrl);
        setCanonicalLink(fullUrl);
    } catch (error) {
        console.error('Error updating meta tags:', error);
    }
}

document.addEventListener("DOMContentLoaded", function () {
    // Listen to changes from Elm
    if (window.app && window.app.ports && window.app.ports.urlChanged) {
        window.app.ports.urlChanged.subscribe((newUrl) => {
            updateMetaTags(newUrl);
        });
    }
});