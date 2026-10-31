#ifndef VCAM_WEB_SERVER_H
#define VCAM_WEB_SERVER_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct WebRequest {
    const char *method;      /* "GET", "POST", "HEAD", etc. */
    const char *path;        /* e.g. "/", "/api/cli" */
    const char *body;        /* request body payload */
    size_t body_len;
} WebRequest;

typedef struct WebResponse {
    int status_code;         /* 200, 400, 404, 500 */
    const char *status_text; /* "OK", "Bad Request", etc. */
    const char *content_type;/* "text/html; charset=utf-8", "application/json", etc. */
    const char *body;        /* response body payload */
    size_t body_len;
} WebResponse;

/* Route handler callback: returns 1 if handled, 0 if not handled */
typedef int (*WebRouteHandler)(const WebRequest *req, WebResponse *res, void *user_data);

typedef struct WebServerConfig {
    int preferred_port;
    int max_port_attempts;
    WebRouteHandler handler;
    void *user_data;
} WebServerConfig;

typedef struct WebServer WebServer;

/* Create a new web server instance. Returns NULL on allocation or socket failure */
WebServer *web_server_create(const WebServerConfig *config);

/* Returns the actual bound port of the server */
int web_server_get_port(const WebServer *server);

/* Runs the blocking accept loop until web_server_stop is called. Returns exit code */
int web_server_run(WebServer *server);

/* Requests the server loop to stop gracefully */
void web_server_stop(WebServer *server);

/* Frees server resources */
void web_server_destroy(WebServer *server);

#ifdef __cplusplus
}
#endif

#endif /* VCAM_WEB_SERVER_H */
