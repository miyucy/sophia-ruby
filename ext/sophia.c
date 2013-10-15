#include "ruby.h"
#include "sophia.h"

#define GetSophia(object, sophia) {                         \
        Data_Get_Struct((object), Sophia, (sophia));        \
        if ((sophia) == NULL) {                             \
            rb_raise(rb_eStandardError, "closed object");   \
        }                                                   \
        if ((sophia)->env == NULL) {                        \
            rb_raise(rb_eStandardError, "closed object");   \
        }                                                   \
        if ((sophia)->db == NULL) {                         \
            rb_raise(rb_eStandardError, "closed object");   \
        }                                                   \
}

static VALUE rb_cSophia;

typedef struct {
    void* env;
    void* db;
} Sophia;

static void
sophia_free(Sophia *sophia)
{
    if (sophia) {
        if (sophia->db) {
            sp_destroy(sophia->db);
        }
        if (sophia->env) {
            sp_destroy(sophia->env);
        }
        xfree(sophia);
    }
}

static void
sophia_mark(Sophia *sophia)
{
}

static VALUE
sophia_alloc(VALUE klass)
{
    Sophia *sophia = ALLOC(Sophia);

    return Data_Wrap_Struct(klass, sophia_mark, sophia_free, sophia);
}

/*
 * call-seq:
 *   Sophia.new("/path/to/db") -> sophia
 */
static VALUE
sophia_initialize(int argc, VALUE *argv, VALUE self)
{
    Sophia *sophia;
    VALUE file;

    Data_Get_Struct(self, Sophia, sophia);

    rb_scan_args(argc, argv, "1", &file);

    FilePathValue(file);

    sophia->env = sp_env();

    if (sophia->env == NULL) {
        rb_raise(rb_eStandardError, "sp_env(3)");
    }

    if (sp_ctl(sophia->env, SPDIR, SPO_CREAT|SPO_RDWR, RSTRING_PTR(file))) {
        rb_raise(rb_eStandardError, sp_error(sophia->env));
    }

    sophia->db = sp_open(sophia->env);

    if (sophia->db == NULL) {
        rb_raise(rb_eStandardError, sp_error(sophia->env));
    }

    return self;
}

/*
 * call-seq:
 *   sophia.close -> nil
 */
static VALUE
sophia_close(VALUE self)
{
    Sophia *sophia;

    GetSophia(self, sophia);

    if (sophia->db) {
        if (sp_destroy(sophia->db)) {
            rb_raise(rb_eStandardError, sp_error(sophia->env));
        }
        sophia->db = NULL;
    }

    if (sophia->env) {
        if (sp_destroy(sophia->env)) {
            rb_raise(rb_eStandardError, sp_error(sophia->env));
        }
        sophia->env = NULL;
    }

    return Qnil;
}

/*
 * call-seq:
 *   Sophia.open("/path/to/db") -> sophia
 *   Sophia.open("/path/to/db") { |sophia| block } -> block
 */
static VALUE
sophia_s_open(int argc, VALUE *argv, VALUE self)
{
    VALUE sophia = sophia_alloc(self);

    if (NIL_P(sophia_initialize(argc, argv, sophia))) {
        return Qnil;
    }

    if (rb_block_given_p()) {
        return rb_ensure(rb_yield, sophia, sophia_close, sophia);
    }

    return sophia;
}

/*
 * call-seq:
 *   sophia.closed? -> true or false
 */
static VALUE
sophia_closed_p(VALUE self)
{
    Sophia *sophia;

    Data_Get_Struct(self, Sophia, sophia);

    if (sophia == NULL) {
        return Qtrue;
    }

    if (sophia->env == NULL) {
        return Qtrue;
    }

    if (sophia->db == NULL) {
        return Qtrue;
    }

    return Qfalse;
}

static VALUE
sophia_set(VALUE self, VALUE key, VALUE value)
{
    Sophia *sophia;

    GetSophia(self, sophia);

    key   = rb_obj_as_string(key);
    value = rb_obj_as_string(value);

    if (sp_set(sophia->db,
               RSTRING_PTR(key), RSTRING_LEN(key),
               RSTRING_PTR(value), RSTRING_LEN(value))) {
        rb_raise(rb_eStandardError, sp_error(sophia->env));
    }

    return value;
}

static VALUE
sophia_get(VALUE self, VALUE key, VALUE ifnone)
{
    Sophia *sophia;
    void   *value;
    size_t  vsize;
    int     result;

    GetSophia(self, sophia);

    ExportStringValue(key);

    result = sp_get(sophia->db,
                    RSTRING_PTR(key), RSTRING_LEN(key),
                    &value, &vsize);

    if (result == 1) {
        return rb_str_new(value, vsize);
    } else if (result == 0) {
        if (NIL_P(ifnone) && rb_block_given_p()) {
            return rb_yield(key);
        } else {
            return ifnone;
        }
    } else if (result == -1) {
        rb_raise(rb_eStandardError, sp_error(sophia->env));
    }

    rb_raise(rb_eStandardError, "error");
    return Qnil;
}

static VALUE
sophia_aref(VALUE self, VALUE key)
{
    return sophia_get(self, key, Qnil);
}

static VALUE
sophia_fetch(int argc, VALUE *argv, VALUE self)
{
    VALUE key, ifnone;
    rb_scan_args(argc, argv, "11", &key, &ifnone);

    return sophia_get(self, key, ifnone);
}

void
Init_sophia()
{
    rb_cSophia = rb_define_class("Sophia", rb_cObject);
    rb_define_alloc_func(rb_cSophia, sophia_alloc);
    rb_include_module(rb_cSophia, rb_mEnumerable); /* include Enumerable */

    rb_define_singleton_method(rb_cSophia, "open", sophia_s_open, -1);

    rb_define_private_method(rb_cSophia, "initialize", sophia_initialize, -1);
    rb_define_method(rb_cSophia, "close",   sophia_close, 0);
    rb_define_method(rb_cSophia, "closed?", sophia_closed_p, 0);
    rb_define_method(rb_cSophia, "set",     sophia_set, 2);
    rb_define_method(rb_cSophia, "[]=",     sophia_set, 2);
    rb_define_method(rb_cSophia, "get",     sophia_aref, 1);
    rb_define_method(rb_cSophia, "[]",      sophia_aref, 1);
    rb_define_method(rb_cSophia, "fetch",   sophia_fetch, -1);
    rb_require("sophia/version");
}
