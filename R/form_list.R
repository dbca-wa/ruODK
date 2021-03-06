#' List all forms.
#'
#' `r lifecycle::badge("stable")`
#'
#' @template param-pid
#' @template param-url
#' @template param-auth
#' @template param-retries
#' @return A tibble with one row per form and all form metadata as columns.
# nolint start
#' @seealso \url{https://odkcentral.docs.apiary.io/#reference/forms-and-submissions/forms}
# nolint end
#' @family form-management
#' @importFrom httr add_headers authenticate content GET
#' @export
#' @examples
#' \dontrun{
#' # See vignette("setup") for setup and authentication options
#' # ruODK::ru_setup(svc = "....svc", un = "me@email.com", pw = "...")
#'
#' # With default pid
#' fl <- form_list()
#'
#' # With explicit pid
#' fl <- form_list(pid = 1)
#'
#' class(fl)
#' # > c("tbl_df", "tbl", "data.frame")
#'
#' # Filter out draft forms (published_at=NA)
#' only_published_forms <- fl %>% dplyr::filter(is.na(published_at))
#'
#' # Note: older ODK Central versions < 1.1 have published_at = NA for both
#' # published and draft forms. Drafts have NA for version and hash.
#' only_published_forms <- fl %>% dplyr::filter(is.na(version) & is.na(hash))
#' }
form_list <- function(pid = get_default_pid(),
                      url = get_default_url(),
                      un = get_default_un(),
                      pw = get_default_pw(),
                      retries = get_retries()) {
  yell_if_missing(url, un, pw, pid = pid)
  httr::RETRY(
    "GET",
    httr::modify_url(url, path = glue::glue("v1/projects/{pid}/forms")),
    httr::add_headers(
      "Accept" = "application/xml",
      "X-Extended-Metadata" = "true"
    ),
    httr::authenticate(un, pw),
    times = retries
  ) %>%
    yell_if_error(., url, un, pw) %>%
    httr::content(.) %>%
    { # nolint
      tibble::tibble(
        name = purrr::map_chr(., "name"),
        fid = purrr::map_chr(., "xmlFormId"),
        version = purrr::map_chr(., "version", .default = NA),
        state = purrr::map_chr(., "state"),
        submissions = purrr::map_chr(., "submissions"),
        created_at = purrr::map_chr(., "createdAt", .default = NA) %>%
          isodt_to_local(),
        created_by_id = purrr::map_int(., c("createdBy", "id")),
        created_by = purrr::map_chr(., c("createdBy", "displayName")),
        updated_at = purrr::map_chr(., "updatedAt", .default = NA) %>%
          isodt_to_local(),
        published_at = purrr::map_chr(., "publishedAt", .default = NA) %>%
          isodt_to_local(),
        last_submission = purrr::map_chr(., "lastSubmission", .default = NA) %>%
          isodt_to_local(),
        hash = purrr::map_chr(., "hash", .default = NA)
      )
    }
}

# usethis::use_test("form_list") # nolint
