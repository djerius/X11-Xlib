#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/XTest.h>
#include "PerlXlib.h"

MODULE = X11::Xlib                PACKAGE = X11::Xlib

# Connection Functions (fn_conn) ---------------------------------------------

void
XOpenDisplay(connection_string = NULL)
    char * connection_string
    INIT:
        Display *dpy;
        SV *tmp, *self;
    PPCODE:
        if (SvTRUE(get_sv("X11::Xlib::_error_fatal_trapped", GV_ADD)))
            croak("Cannot call further Xlib functions after fatal Xlib error");
        dpy= XOpenDisplay(connection_string);
        self= PerlXlib_obj_for_display(dpy, 1);
        if (SvROK(self)) {
            if (!hv_store((HV*) SvRV(self), "autoclose", 9, (tmp=newSViv(1)), 0)) {
                sv_2mortal(tmp);
                croak("Failed to set autoclose");
            }
        }
        PUSHs(self);

void
_pointer_value(obj)
    SV *obj
    INIT:
        Display *dpy;
        SV **fp= NULL;
    PPCODE:
        dpy= PerlXlib_get_magic_dpy(obj, 0);
        if (!dpy && SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVHV) {
            // in the case of a dead connection, the pointer value moves to a hash field
            fp= hv_fetch((HV*)SvRV(obj), "_pointer_value", 14, 0);
        }
        PUSHs(dpy? sv_2mortal(newSVpvn((const char*)&dpy, sizeof(dpy)))
            : (fp && *fp && SvPOK(*fp))? *fp
            : &PL_sv_undef);

void
_set_pointer_value(obj, dpy_val)
    SV *obj
    SV *dpy_val
    PPCODE:
        if (SvOK(dpy_val) && (!SvPOK(dpy_val) || SvCUR(dpy_val) != sizeof(Display*)))
            croak("Invalid pointer value (should be scalar of %d bytes)", sizeof(Display*));
        PerlXlib_set_magic_dpy(obj, SvOK(dpy_val)? (Display*)(void*)SvPVX(dpy_val) : NULL);

char *
XServerVendor(dpy)
    Display * dpy

int
XVendorRelease(dpy)
    Display * dpy

int
ConnectionNumber(dpy)
    Display * dpy

void
XSetCloseDownMode(dpy, close_mode)
    Display * dpy
    int close_mode
    CODE:
        XSetCloseDownMode(dpy, close_mode);

void
XCloseDisplay(dpy_sv)
    SV *dpy_sv
    INIT:
        Display *dpy;
    CODE:
        dpy= PerlXlib_get_magic_dpy(dpy_sv, 1);
        XCloseDisplay(dpy);
        PerlXlib_set_magic_dpy(dpy_sv, NULL); // mark as closed
        hv_delete((HV*)SvRV(dpy_sv), "autoclose", 9, G_DISCARD);

# Event Functions (fn_event) -------------------------------------------------

void
XNextEvent(dpy, event_sv)
    Display * dpy
    SV *event_sv
    INIT:
        XEvent *event;
    CODE:
        event= (XEvent*) PerlXlib_get_struct_ptr(
            event_sv, 2,
            "X11::Xlib::XEvent", sizeof(XEvent),
            (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
        );
        XNextEvent(dpy, event);
        sv_bless(event_sv, gv_stashpv(PerlXlib_xevent_pkg_for_type(event->type), GV_ADD));

Bool
XCheckWindowEvent(dpy, wnd, event_mask, event_return)
    Display * dpy
    Window wnd
    int event_mask
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckWindowEvent(dpy, wnd, event_mask, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XCheckTypedWindowEvent(dpy, wnd, event_type, event_return)
    Display * dpy
    Window wnd
    int event_type
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckTypedWindowEvent(dpy, wnd, event_type, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XCheckMaskEvent(dpy, event_mask, event_return)
    Display * dpy
    int event_mask
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckMaskEvent(dpy, event_mask, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XCheckTypedEvent(dpy, event_type, event_return)
    Display * dpy
    int event_type
    SV *event_return
    INIT:
        XEvent event, *dest;
    CODE:
        RETVAL= XCheckTypedEvent(dpy, event_type, &event);
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 2,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

Bool
XSendEvent(dpy, wnd, propagate, event_mask, event_send)
    Display * dpy
    Window wnd
    Bool propagate
    long event_mask
    XEvent *event_send

void
XPutBackEvent(dpy, event)
    Display * dpy
    XEvent *event

void
XFlush(dpy)
    Display * dpy

void
XSync(dpy, discard=0)
    Display *  dpy
    int discard

void
XSelectInput(dpy, wnd, mask)
    Display * dpy
    Window wnd
    int mask

Bool
_wait_event(dpy, wnd, event_type, event_mask, event_return, max_wait_msec)
    Display * dpy
    Window wnd
    int event_type
    int event_mask
    SV *event_return
    int max_wait_msec
    INIT:
        XEvent event, *dest;
        int retried= 0;
        fd_set fds;
        int x11_fd;
        struct timeval tv;
    CODE:
        retry:
        RETVAL= wnd && event_type? XCheckTypedWindowEvent(dpy, wnd, event_type, &event)
              : wnd?               XCheckWindowEvent(dpy, wnd, event_mask, &event)
              : event_type?        XCheckTypedEvent(dpy, event_type, &event)
              :                    XCheckMaskEvent(dpy, event_mask, &event);
        if (!RETVAL && !retried) {
            x11_fd= ConnectionNumber(dpy);
            tv.tv_sec= max_wait_msec / 1000;
            tv.tv_usec= (max_wait_msec % 1000)*1000;
            FD_ZERO(&fds);
            FD_SET(x11_fd, &fds);
            if (select(x11_fd+1, &fds, NULL, &fds, &tv) > 0) {
                retried= 1;
                goto retry;
            }
        }
        if (RETVAL) {
            dest= (XEvent*) PerlXlib_get_struct_ptr(
                event_return, 1,
                PerlXlib_xevent_pkg_for_type(event.type), sizeof(XEvent),
                (PerlXlib_struct_pack_fn*) PerlXlib_XEvent_pack
            );
            memcpy(dest, &event, sizeof(event));
        }
    OUTPUT:
        RETVAL

# Screen Functions (fn_screen) -----------------------------------------------

int
DefaultScreen(dpy)
    Display * dpy

int
ScreenCount(dpy)
    Display * dpy

Window
RootWindow(dpy, screen=DefaultScreen(dpy))
    Display *  dpy
    ScreenNumber screen
    CODE:
        RETVAL = RootWindow(dpy, screen);
    OUTPUT:
        RETVAL

Colormap
DefaultColormap(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DefaultDepth(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

GC
DefaultGC(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

Visual *
DefaultVisual(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayWidth(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayHeight(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayWidthMM(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

int
DisplayHeightMM(dpy, screen=DefaultScreen(dpy))
    Display * dpy
    ScreenNumber screen

# Visual Functions (fn_vis) --------------------------------------------------

Bool
XMatchVisualInfo(dpy, screen, depth, class, vis_return)
    Display * dpy
    ScreenNumber screen
    int depth
    int class
    XVisualInfo *vis_return

void
XGetVisualInfo(dpy, vinfo_mask, vinfo_template)
    Display * dpy
    int vinfo_mask
    XVisualInfo *vinfo_template
    INIT:
        XVisualInfo *list;
        int n= 0, i;
    PPCODE:
        list= XGetVisualInfo(dpy, vinfo_mask, vinfo_template, &n);
        if (list) {
            for (i= 0; i<n; i++) {
                PUSHs(sv_2mortal(
                    sv_setref_pvn(newSV(0), "X11::Xlib::XVisualInfo", (void*)(list+i), sizeof(XVisualInfo))
                ));
            }
            XFree(list);
        }

int
XVisualIDFromVisual(vis)
    Visual *vis

Colormap
XCreateColormap(dpy, wnd=RootWindow(dpy, DefaultScreen(dpy)), visual=DefaultVisual(dpy, DefaultScreen(dpy)), alloc=AllocNone)
    Display * dpy
    Window wnd
    Visual *visual
    int alloc

void
XFreeColormap(dpy, cmap)
    Display * dpy
    int cmap

# Pixmap Functions (fn_pix) --------------------------------------------------

Pixmap
XCreatePixmap(dpy, drw, width, height, depth)
    Display * dpy
    Drawable drw
    int width
    int height
    int depth

void
XFreePixmap(dpy, pix)
    Display * dpy
    Pixmap pix

Pixmap
XCreateBitmapFromData(dpy, drw, data, width, height)
    Display * dpy
    Drawable drw
    SV * data
    int width
    int height
    CODE:
        if (!SvPOK(data) || SvCUR(data) < ( (width * height + 7) / 8 ))
            croak( "'data' must be at least %d bytes long", ( (width * height + 7) / 8 ));
        RETVAL = XCreateBitmapFromData(dpy, drw, SvPVX(data), width, height);
    OUTPUT:
        RETVAL

Pixmap
XCreatePixmapFromBitmapData(dpy, drw, data, width, height, fg, bg, depth)
    Display * dpy
    Drawable drw
    SV * data
    int width
    int height
    long fg
    long bg
    int depth
    CODE:
        if (!SvPOK(data) || SvCUR(data) < ( (width * height + 7) / 8 ))
            croak( "'data' must be at least %d bytes long", ( (width * height + 7) / 8 ));
        RETVAL = XCreatePixmapFromBitmapData(dpy, drw, SvPVX(data), width, height, fg, bg, depth);
    OUTPUT:
        RETVAL

# Window Functions (fn_win) --------------------------------------------------

Window
XCreateWindow(dpy, parent, x, y, w, h, border, depth, class, visual, attr_mask, attrs)
    Display * dpy
    Window parent
    int x
    int y
    int w
    int h
    int border
    int depth
    int class
    VisualOrNull visual
    int attr_mask
    XSetWindowAttributes *attrs

Window
XCreateSimpleWindow(dpy, parent, x, y, w, h, border_width, border_color, background_color)
    Display * dpy
    Window parent
    int x
    int y
    int w
    int h
    int border_width
    int border_color
    int background_color

void
XMapWindow(dpy, wnd)
    Display * dpy
    Window wnd

void
XUnmapWindow(dpy, wnd)
    Display * dpy
    Window wnd

int
XGetGeometry(dpy, wnd, root_out=NULL, x_out=NULL, y_out=NULL, width_out=NULL, height_out=NULL, border_out=NULL, depth_out=NULL)
    Display * dpy
    Window wnd
    SV *root_out
    SV *x_out
    SV *y_out
    SV *width_out
    SV *height_out
    SV *border_out
    SV *depth_out
    INIT:
        Window root;
        int x, y;
        unsigned int w, h, bw, d;
    CODE:
        RETVAL = XGetGeometry(dpy, wnd, &root, &x, &y, &w, &h, &bw, &d);
        if (root_out)   sv_setuv(root_out, root);
        if (x_out)      sv_setiv(x_out, x);
        if (y_out)      sv_setiv(y_out, y);
        if (width_out)  sv_setuv(width_out, w);
        if (height_out) sv_setuv(height_out, h);
        if (border_out) sv_setuv(border_out, bw);
        if (depth_out)  sv_setuv(depth_out, d);
    OUTPUT:
        RETVAL

int
XGetWMSizeHints(dpy, wnd, hints_out, supplied_out, property)
    Display * dpy
    Window wnd
    XSizeHints *hints_out
    SV *supplied_out
    Atom property
    INIT:
        long supplied;
    CODE:
        RETVAL = XGetWMSizeHints(dpy, wnd, hints_out, &supplied, property);
        sv_setiv(supplied_out, supplied);
    OUTPUT:
        RETVAL

void
XSetWMSizeHints(dpy, wnd, hints, property)
    Display * dpy
    Window wnd
    XSizeHints *hints
    Atom property

int
XGetWMNormalHints(dpy, wnd, hints_out, supplied_out)
    Display * dpy
    Window wnd
    SV *hints_out
    SV *supplied_out
    INIT:
        long supplied;
        XSizeHints hints, *dest;
    CODE:
        RETVAL = XGetWMNormalHints(dpy, wnd, &hints, &supplied);
        if (RETVAL) {
            dest= (XSizeHints*) PerlXlib_get_struct_ptr(
                hints_out, 1,
                "X11::Xlib::XSizeHints", sizeof(XSizeHints),
                (PerlXlib_struct_pack_fn*) PerlXlib_XSizeHints_pack
            );
            memcpy(dest, &hints, sizeof(hints));
            sv_setiv(supplied_out, supplied);
        }
    OUTPUT:
        RETVAL

void
XSetWMNormalHints(dpy, wnd, hints)
    Display * dpy
    Window wnd
    XSizeHints *hints

void
XDestroyWindow(dpy, wnd)
    Display * dpy
    Window wnd

# XTest Functions (fn_xtest) -------------------------------------------------

int
XTestFakeMotionEvent(dpy, screen, x, y, EventSendDelay = 10)
    Display *  dpy
    int screen
    int x
    int y
    int EventSendDelay

int
XTestFakeButtonEvent(dpy, button, pressed, EventSendDelay = 10);
    Display *  dpy
    int button
    int pressed
    int EventSendDelay

int
XTestFakeKeyEvent(dpy, kc, pressed, EventSendDelay = 10)
    Display *  dpy
    unsigned char kc
    int pressed
    int EventSendDelay

void
XBell(dpy, percent)
    Display *  dpy
    int percent

void
XQueryKeymap(dpy)
    Display *  dpy
    PREINIT:
        char keys_return[32];
        int i, j;
    PPCODE:
        XQueryKeymap(dpy, keys_return);
        for(i=0; i<32; i++) {
            for (j=0; j<8;j++) {
                if (keys_return[i] & (1 << j))
                    XPUSHs(sv_2mortal(newSViv(i * 8 + j)));
            }
        }

# KeySym Utility Functions (fn_keysym) ---------------------------------------

char *
XKeysymToString(keysym)
    KeySym keysym
    CODE:
        RETVAL = XKeysymToString(keysym);
    OUTPUT:
        RETVAL

unsigned long
XStringToKeysym(string)
    char * string
    CODE:
        RETVAL = XStringToKeysym(string);
    OUTPUT:
        RETVAL

void
keysym_to_codepoint(keysym)
    KeySym keysym
    INIT:
        int codepoint;
    PPCODE:
        codepoint= PerlXlib_keysym_to_codepoint(keysym);
        PUSHs(codepoint >= 0? newSViv(codepoint) : &PL_sv_undef);

void
codepoint_to_keysym(codepoint)
    int codepoint
    INIT:
        KeySym sym;
    PPCODE:
        sym= PerlXlib_codepoint_to_keysym(codepoint);
        PUSHs(sym > 0? newSViv(sym) : &PL_sv_undef);

void
keysym_to_char(keysym)
    KeySym keysym
    INIT:
        int codepoint;
    PPCODE:
        codepoint= PerlXlib_keysym_to_codepoint(keysym);
        PUSHs(codepoint >= 0? newSVpvf("%c", codepoint) : &PL_sv_undef);

void
char_to_keysym(str)
    SV *str
    INIT:
        int codepoint;
        KeySym sym;
        const char *s;
        size_t len;
    PPCODE:
        s= SvPV(str, len);
        codepoint= NATIVE_TO_UNI(DO_UTF8(str)? utf8_to_uvchr_buf(s, s+len, &len) : s[0]);
        sym= PerlXlib_codepoint_to_keysym(codepoint);
        PUSHs(codepoint > 0 && sym > 0? newSViv(sym) : &PL_sv_undef);

int
IsKeypadKey(keysym)
    unsigned long keysym

int
IsPrivateKeypadKey(keysym)
    unsigned long keysym

int
IsPFKey(keysym)
    unsigned long keysym

int
IsFunctionKey(keysym)
    unsigned long keysym

int
IsMiscFunctionKey(keysym)
    unsigned long keysym

int
IsModifierKey(keysym)
    unsigned long keysym

void
XConvertCase(ksym, lowercase, uppercase)
    KeySym ksym
    SV *lowercase
    SV *uppercase
    INIT:
        KeySym lc, uc;
    PPCODE:
        XConvertCase(ksym, &lc, &uc);
        sv_setiv(lowercase, lc);
        sv_setiv(uppercase, uc);

# Input Functions (fn_input) -------------------------------------------------

unsigned long
keyboard_leds(dpy)
    Display *  dpy;
    PREINIT:
        XKeyboardState state;
    CODE:
        XGetKeyboardControl(dpy, &state);
        RETVAL = state.led_mask;
    OUTPUT:
        RETVAL

void
_auto_repeat(dpy)
    Display *  dpy;
    PREINIT:
        XKeyboardState state;
        int i, j;
    CODE:
        XGetKeyboardControl(dpy, &state);
        for(i=0; i<32; i++) {
            for (j=0; j<8; j++) {
                if (state.auto_repeats[i] & (1 << j))
                    XPUSHs(sv_2mortal(newSViv(i * 8 + j)));
            }
        }

# Keyboard Mapping Functions (fn_keymap) -------------------------------------

void
XDisplayKeycodes(dpy, minkey_sv, maxkey_sv)
    Display *dpy
    SV *minkey_sv
    SV *maxkey_sv
    INIT:
        int minkey, maxkey;
    PPCODE:
        XDisplayKeycodes(dpy, &minkey, &maxkey);
        sv_setiv(minkey_sv, minkey);
        sv_setiv(maxkey_sv, maxkey);

void
XGetKeyboardMapping(dpy, fkeycode, count = 1)
    Display * dpy
    unsigned int fkeycode
    int count
    PREINIT:
        int creturn;
        KeySym * keysym;
        int i = 0;
    PPCODE:
        keysym = XGetKeyboardMapping(dpy, fkeycode, count, &creturn);
        EXTEND(SP, creturn * count -1);
        for (i=0; i < creturn * count; i++)
            XPUSHs(sv_2mortal(newSVuv(keysym[i])));
        XFree(keysym);

void
load_keymap(dpy, symbolic=2, minkey=0, maxkey=255)
    Display *dpy
    int symbolic
    int minkey
    int maxkey
    INIT:
        int xmin, xmax, i, j, nsym;
        KeySym *syms, sym;
        AV *tbl, *row;
        SV *sv;
    PPCODE:
        XDisplayKeycodes(dpy, &xmin, &xmax);
        if (xmin < minkey) xmin= minkey;
        if (xmax > maxkey) xmax= maxkey;
        syms= XGetKeyboardMapping(dpy, xmin, xmax-xmin+1, &nsym);
        if (!syms)
            croak("XGetKeyboardMapping failed");
        tbl= newAV();
        PUSHs(sv_2mortal(newRV_noinc((SV*) tbl)));
        av_extend(tbl, maxkey);
        for (i= minkey; i < xmin; i++)
            av_push(tbl, newSVsv(&PL_sv_undef));
        for (i= 0; i <= xmax-xmin; i++) {
            row= newAV();
            av_push(tbl, newRV_noinc((SV*) row));
            av_extend(row, nsym-1);
            for (j= 0; j < nsym; j++) {
                if (syms[i*nsym+j]) {
                    sv= PerlXlib_keysym_to_sv(syms[i*nsym+j], symbolic);
                    if (!sv) {
                        XFree(syms);
                        croak("Your keymap includes KeySym 0x%x that can't be un-ambiguously represented by a string", syms[i*nsym+j]);
                    }
                    av_store(row, j, sv);
                }
            }
        }
        XFree(syms);

void
save_keymap(dpy, kmap, minkey=0, maxkey=255)
    Display *dpy
    AV *kmap
    int minkey
    int maxkey
    INIT:
        int xmin, xmax, amin, nsym, i, j, n, m, codepoint, ival;
        size_t len;
        const char *name;
        char *endp;
        KeySym *syms, cursym;
        SV **elem, *buf;
        AV *row;
    PPCODE:
        m= av_len(kmap);
        if (minkey < 0 || maxkey > 255 || minkey > maxkey || m < 0)
            croak("require 0 <= min <= max <= 255 and non-zero length array");
        XDisplayKeycodes(dpy, &xmin, &xmax);
        if (xmin < minkey) xmin= minkey;
        if (xmax > maxkey) xmax= maxkey;
        // If the length of the array is equal to maxkey-minkey, then assume the elements
        // are exactly min..max.  Else if the array is longer, assume the array starts at 0
        // and min..max are indexes into the array
        amin= (m == maxkey - minkey)? minkey : 0;
        if (maxkey - amin > m && maxkey < 255)
            croak("max exceeds array length");
        if (xmax - amin > m)
            xmax= m - amin;
        // Find the longest array in the bunch
        nsym= 0;
        for (i= 0; i < xmax-xmin+1; i++) {
            elem= av_fetch(kmap, i + (xmin-amin), 0);
            if (!elem || !*elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVAV)
                croak("Expected arrayref of arrayrefs (defined for the range %d..%d)", xmin-amin, xmax-amin);
            n= av_len((AV*) SvRV(*elem))+1;
            if (nsym < n) nsym= n;
        }
        // Allocate buffer in a temp SV in case we croak
        buf= newSV(nsym * (xmax-xmin+1) * sizeof(KeySym));
        syms= (KeySym*) SvPVX(buf);
        for (i= 0; i < xmax-xmin+1; i++) {
            row= (AV*) SvRV(*av_fetch(kmap, i + (xmin-amin), 0));
            for (j= 0, n= av_len(row)+1; j < nsym; j++) {
                cursym= NoSymbol;
                if (j < n) {
                    elem= av_fetch(row, j, 0);
                    if (elem && *elem && SvOK(*elem)) {
                        cursym= PerlXlib_sv_to_keysym(*elem);
                        if (cursym == NoSymbol)
                            croak("No such KeySym %s (slot %d of keycode %d)", name, j, i+xmin);
                    }
                }
                syms[ i * nsym + j ]= cursym;
            }
        }
        XChangeKeyboardMapping(dpy, xmin, nsym, syms, xmax-xmin+1);

void
XGetModifierMapping(dpy)
    Display *dpy
    INIT:
        XModifierKeymap *modmap;
        AV *tbl, *row;
        int i, j;
    PPCODE:
        modmap= XGetModifierMapping(dpy);
        tbl= newAV();
        av_extend(tbl, 8);
        for (i= 0; i < 8; i++) {
            row= newAV();
            av_extend(row, modmap->max_keypermod);
            for (j= 0; j < modmap->max_keypermod; j++) {
                av_push(row, newSViv(modmap->modifiermap[i * modmap->max_keypermod + j]));
            }
            av_push(tbl, newRV_noinc((SV*) row));
        }
        XFree(modmap);
        PUSHs(sv_2mortal(newRV_noinc((SV*) tbl)));

int
XSetModifierMapping(dpy, tbl)
    Display *dpy
    AV *tbl
    INIT:
        XModifierKeymap modmap;
        KeyCode keycodes[64];
        int i, n, j, code, minkey, maxkey;
        SV **elem;
        AV *row;
    CODE:
        memset(keycodes, 0, sizeof(keycodes));
        modmap.max_keypermod= 0;
        modmap.modifiermap= keycodes;
        XDisplayKeycodes(dpy, &minkey, &maxkey);
        // Find the longest array.  Also validate.
        if (av_len(tbl) != 7)
            croak("Expected arrayref of length 8");
        for (i= 0; i < 8; i++) {
            elem= av_fetch(tbl, i, 0);
            if (!elem || !*elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVAV)
                croak("Expected arrayref of arrayrefs");
            row= (AV*) SvRV(*elem);
            n= av_len(row)+1;
            if (n > 8)
                croak("There can be at most 8 keys per modifier");
            if (n > modmap.max_keypermod)
                modmap.max_keypermod= n;
            for (j= 0; j < n; j++) {
                elem= av_fetch(row, j, 0);
                if (elem && *elem && SvOK(*elem)) {
                    code= SvIV(*elem);
                    if (code != 0 && (code < minkey || code > maxkey))
                        croak("Keycode %d outside range of %d..%d", code, minkey, maxkey);
                    keycodes[i*8+j]= code;
                }
            }
        }
        // If the number of modifiers is less than the max, shrink the table
        // rows to match.
        if (modmap.max_keypermod < 8) {
            n= modmap.max_keypermod;
            if (n == 0)
                croak("Cowardly refusing to set an empty modifiermap");
            for (i= 1; i < 8; i++)
                for (j= 0; j < n; j++)
                    keycodes[i * n + j]= keycodes[i * 8 + j];
        }
        RETVAL= XSetModifierMapping(dpy, &modmap);
    OUTPUT:
        RETVAL

void
XLookupString(event, str_sv, keysym_sv= NULL)
    XEvent *event
    SV *str_sv
    SV *keysym_sv
    INIT:
        size_t len, maxlen;
        KeySym sym;
    PPCODE:
        if (event->type != KeyPress && event->type != KeyRelease)
            croak("Expected event of type KeyPress or KeyRelease");
        if (!event->xany.display)
            croak("event->display must be set");
        if (SvOK(str_sv))
            SvPV_force(str_sv, len);
        else {
            sv_setpvn(str_sv, "", 0);
            len= 0;
        }
        maxlen= len < 16? 16 : len;
        SvGROW(str_sv, maxlen);
        len= XLookupString((XKeyEvent*) event, SvPVX(str_sv), maxlen-1, &sym, NULL);
        // If full buffer, try one more time with quadruple buffer space
        if (len == maxlen-1) {
            maxlen <<= 2;
            SvGROW(str_sv, maxlen);
            len= XLookupString((XKeyEvent*) event, SvPVX(str_sv), maxlen-1, &sym, NULL);
        }
        SvPVX(str_sv)[len]= '\0';
        SvCUR_set(str_sv, len);
        if (keysym_sv)
            sv_setiv(keysym_sv, sym);

unsigned int
XKeysymToKeycode(dpy, keysym)
    Display * dpy
    unsigned long keysym
    CODE:
        RETVAL = XKeysymToKeycode(dpy, keysym);
    OUTPUT:
        RETVAL

void
XRefreshKeyboardMapping(event)
    XEvent *event
    PPCODE:
        if (event->type != MappingNotify)
            croak("Expected event of type MappingNotify");
        XRefreshKeyboardMapping((XMappingEvent*) event);

void
_error_names()
    INIT:
        HV* codes;
        char intbuf[sizeof(long)*3+2];
    PPCODE:
        codes= get_hv("X11::Xlib::_error_names", 0);
        if (!codes) {
            codes= get_hv("X11::Xlib::_error_names", GV_ADD);
#define E(name) if (!hv_store(codes, intbuf, snprintf(intbuf, sizeof(intbuf), "%d", name), newSVpv(#name,0), 0)) die("hv_store");
            E(BadAccess)
            E(BadAlloc)
            E(BadAtom)
            E(BadColor)
            E(BadCursor)
            E(BadDrawable)
            E(BadFont)
            E(BadGC)
            E(BadIDChoice)
            E(BadImplementation)
            E(BadLength)
            E(BadMatch)
            E(BadName)
            E(BadPixmap)
            E(BadRequest)
            E(BadValue)
            E(BadWindow)
#undef E
        }
        PUSHs(sv_2mortal((SV*)newRV((SV*)codes)));

void
_install_error_handlers(nonfatal,fatal)
    Bool nonfatal
    Bool fatal
    CODE:
        PerlXlib_install_error_handlers(nonfatal, fatal);

MODULE = X11::Xlib                PACKAGE = X11::Xlib::Visual

int
id(visual)
    Visual *visual
    CODE:
        RETVAL = XVisualIDFromVisual(visual);
    OUTPUT:
        RETVAL

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XEvent

# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XEvent
void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XEvent", sizeof(XEvent),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XEvent_pack
        );
        memset((void*) sptr, 0, sizeof(XEvent));

int
_sizeof(ignored)
    SV *ignored
    CODE:
        RETVAL = sizeof(XEvent);
    OUTPUT:
        RETVAL

void
_pack(e, fields, consume)
    XEvent *e
    HV *fields
    Bool consume
    INIT:
        const char *oldpkg, *newpkg;
    PPCODE:
        oldpkg= PerlXlib_xevent_pkg_for_type(e->type);
        PerlXlib_XEvent_pack(e, fields, consume);
        newpkg= PerlXlib_xevent_pkg_for_type(e->type);
        // re-bless the object if the thing passed to us was actually an object
        if (oldpkg != newpkg && sv_derived_from(ST(0), "X11::Xlib::XEvent"))
            sv_bless(ST(0), gv_stashpv(newpkg, GV_ADD));

void
_unpack(e, fields)
    XEvent *e
    HV *fields
    PPCODE:
        PerlXlib_XEvent_unpack(e, fields);

void
_above(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.above = c_value; } else { c_value= event->xconfigure.above; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.above = c_value; } else { c_value= event->xconfigurerequest.above; } break;
    default: croak("Can't access XEvent.above for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_atom(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case PropertyNotify:
      if (value) { event->xproperty.atom = c_value; } else { c_value= event->xproperty.atom; } break;
    default: croak("Can't access XEvent.atom for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_b(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ClientMessage:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(char)*20)  croak("Expected scalar of length %d but got %d", sizeof(char)*20, SvCUR(value)); memcpy(event->xclient.data.b, SvPVX(value), sizeof(char)*20);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xclient.data.b, sizeof(char)*20))); } break;
    default: croak("Can't access XEvent.b for type=%d", event->type);
    }

void
_border_width(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.border_width = c_value; } else { c_value= event->xconfigure.border_width; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.border_width = c_value; } else { c_value= event->xconfigurerequest.border_width; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.border_width = c_value; } else { c_value= event->xcreatewindow.border_width; } break;
    default: croak("Can't access XEvent.border_width for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_button(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned int c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.button = c_value; } else { c_value= event->xbutton.button; } break;
    default: croak("Can't access XEvent.button for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_colormap(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Colormap c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ColormapNotify:
      if (value) { event->xcolormap.colormap = c_value; } else { c_value= event->xcolormap.colormap; } break;
    default: croak("Can't access XEvent.colormap for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_cookie(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned int c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    default: croak("Can't access XEvent.cookie for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_count(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case Expose:
      if (value) { event->xexpose.count = c_value; } else { c_value= event->xexpose.count; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.count = c_value; } else { c_value= event->xgraphicsexpose.count; } break;
    case MappingNotify:
      if (value) { event->xmapping.count = c_value; } else { c_value= event->xmapping.count; } break;
    default: croak("Can't access XEvent.count for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_detail(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.detail = c_value; } else { c_value= event->xconfigurerequest.detail; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.detail = c_value; } else { c_value= event->xcrossing.detail; } break;
    case FocusIn:
    case FocusOut:
      if (value) { event->xfocus.detail = c_value; } else { c_value= event->xfocus.detail; } break;
    default: croak("Can't access XEvent.detail for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
display(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    if (value) {
      event->xany.display= PerlXlib_get_magic_dpy(value, 0);
      PUSHs(value);
    } else {
      PUSHs(PerlXlib_obj_for_display(event->xany.display, 0));
    }

void
_drawable(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Drawable c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.drawable = c_value; } else { c_value= event->xgraphicsexpose.drawable; } break;
    case NoExpose:
      if (value) { event->xnoexpose.drawable = c_value; } else { c_value= event->xnoexpose.drawable; } break;
    default: croak("Can't access XEvent.drawable for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_event(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case CirculateNotify:
      if (value) { event->xcirculate.event = c_value; } else { c_value= event->xcirculate.event; } break;
    case ConfigureNotify:
      if (value) { event->xconfigure.event = c_value; } else { c_value= event->xconfigure.event; } break;
    case DestroyNotify:
      if (value) { event->xdestroywindow.event = c_value; } else { c_value= event->xdestroywindow.event; } break;
    case GravityNotify:
      if (value) { event->xgravity.event = c_value; } else { c_value= event->xgravity.event; } break;
    case MapNotify:
      if (value) { event->xmap.event = c_value; } else { c_value= event->xmap.event; } break;
    case ReparentNotify:
      if (value) { event->xreparent.event = c_value; } else { c_value= event->xreparent.event; } break;
    case UnmapNotify:
      if (value) { event->xunmap.event = c_value; } else { c_value= event->xunmap.event; } break;
    default: croak("Can't access XEvent.event for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_evtype(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case GenericEvent:
      if (value) { event->xgeneric.evtype = c_value; } else { c_value= event->xgeneric.evtype; } break;
    default: croak("Can't access XEvent.evtype for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_extension(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case GenericEvent:
      if (value) { event->xgeneric.extension = c_value; } else { c_value= event->xgeneric.extension; } break;
    default: croak("Can't access XEvent.extension for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_first_keycode(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case MappingNotify:
      if (value) { event->xmapping.first_keycode = c_value; } else { c_value= event->xmapping.first_keycode; } break;
    default: croak("Can't access XEvent.first_keycode for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_focus(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.focus = c_value; } else { c_value= event->xcrossing.focus; } break;
    default: croak("Can't access XEvent.focus for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_format(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ClientMessage:
      if (value) { event->xclient.format = c_value; } else { c_value= event->xclient.format; } break;
    default: croak("Can't access XEvent.format for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_from_configure(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case UnmapNotify:
      if (value) { event->xunmap.from_configure = c_value; } else { c_value= event->xunmap.from_configure; } break;
    default: croak("Can't access XEvent.from_configure for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_height(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.height = c_value; } else { c_value= event->xconfigure.height; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.height = c_value; } else { c_value= event->xconfigurerequest.height; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.height = c_value; } else { c_value= event->xcreatewindow.height; } break;
    case Expose:
      if (value) { event->xexpose.height = c_value; } else { c_value= event->xexpose.height; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.height = c_value; } else { c_value= event->xgraphicsexpose.height; } break;
    case ResizeRequest:
      if (value) { event->xresizerequest.height = c_value; } else { c_value= event->xresizerequest.height; } break;
    default: croak("Can't access XEvent.height for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_is_hint(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    char c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case MotionNotify:
      if (value) { event->xmotion.is_hint = c_value; } else { c_value= event->xmotion.is_hint; } break;
    default: croak("Can't access XEvent.is_hint for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_key_vector(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case KeymapNotify:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(char)*32)  croak("Expected scalar of length %d but got %d", sizeof(char)*32, SvCUR(value)); memcpy(event->xkeymap.key_vector, SvPVX(value), sizeof(char)*32);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xkeymap.key_vector, sizeof(char)*32))); } break;
    default: croak("Can't access XEvent.key_vector for type=%d", event->type);
    }

void
_keycode(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned int c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.keycode = c_value; } else { c_value= event->xkey.keycode; } break;
    default: croak("Can't access XEvent.keycode for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_l(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ClientMessage:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(long)*5)  croak("Expected scalar of length %d but got %d", sizeof(long)*5, SvCUR(value)); memcpy(event->xclient.data.l, SvPVX(value), sizeof(long)*5);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xclient.data.l, sizeof(long)*5))); } break;
    default: croak("Can't access XEvent.l for type=%d", event->type);
    }

void
_major_code(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.major_code = c_value; } else { c_value= event->xgraphicsexpose.major_code; } break;
    case NoExpose:
      if (value) { event->xnoexpose.major_code = c_value; } else { c_value= event->xnoexpose.major_code; } break;
    default: croak("Can't access XEvent.major_code for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_message_type(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ClientMessage:
      if (value) { event->xclient.message_type = c_value; } else { c_value= event->xclient.message_type; } break;
    default: croak("Can't access XEvent.message_type for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_minor_code(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.minor_code = c_value; } else { c_value= event->xgraphicsexpose.minor_code; } break;
    case NoExpose:
      if (value) { event->xnoexpose.minor_code = c_value; } else { c_value= event->xnoexpose.minor_code; } break;
    default: croak("Can't access XEvent.minor_code for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_mode(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.mode = c_value; } else { c_value= event->xcrossing.mode; } break;
    case FocusIn:
    case FocusOut:
      if (value) { event->xfocus.mode = c_value; } else { c_value= event->xfocus.mode; } break;
    default: croak("Can't access XEvent.mode for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_new(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ColormapNotify:
      if (value) { event->xcolormap.new = c_value; } else { c_value= event->xcolormap.new; } break;
    default: croak("Can't access XEvent.new for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_override_redirect(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.override_redirect = c_value; } else { c_value= event->xconfigure.override_redirect; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.override_redirect = c_value; } else { c_value= event->xcreatewindow.override_redirect; } break;
    case MapNotify:
      if (value) { event->xmap.override_redirect = c_value; } else { c_value= event->xmap.override_redirect; } break;
    case ReparentNotify:
      if (value) { event->xreparent.override_redirect = c_value; } else { c_value= event->xreparent.override_redirect; } break;
    default: croak("Can't access XEvent.override_redirect for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_owner(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionRequest:
      if (value) { event->xselectionrequest.owner = c_value; } else { c_value= event->xselectionrequest.owner; } break;
    default: croak("Can't access XEvent.owner for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_pad(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    default: croak("Can't access XEvent.pad for type=%d", event->type);
    }

void
_parent(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case CirculateRequest:
      if (value) { event->xcirculaterequest.parent = c_value; } else { c_value= event->xcirculaterequest.parent; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.parent = c_value; } else { c_value= event->xconfigurerequest.parent; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.parent = c_value; } else { c_value= event->xcreatewindow.parent; } break;
    case MapRequest:
      if (value) { event->xmaprequest.parent = c_value; } else { c_value= event->xmaprequest.parent; } break;
    case ReparentNotify:
      if (value) { event->xreparent.parent = c_value; } else { c_value= event->xreparent.parent; } break;
    default: croak("Can't access XEvent.parent for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_place(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case CirculateNotify:
      if (value) { event->xcirculate.place = c_value; } else { c_value= event->xcirculate.place; } break;
    case CirculateRequest:
      if (value) { event->xcirculaterequest.place = c_value; } else { c_value= event->xcirculaterequest.place; } break;
    default: croak("Can't access XEvent.place for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_property(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.property = c_value; } else { c_value= event->xselection.property; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.property = c_value; } else { c_value= event->xselectionrequest.property; } break;
    default: croak("Can't access XEvent.property for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_request(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case MappingNotify:
      if (value) { event->xmapping.request = c_value; } else { c_value= event->xmapping.request; } break;
    default: croak("Can't access XEvent.request for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_requestor(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.requestor = c_value; } else { c_value= event->xselection.requestor; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.requestor = c_value; } else { c_value= event->xselectionrequest.requestor; } break;
    default: croak("Can't access XEvent.requestor for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_root(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.root = c_value; } else { c_value= event->xbutton.root; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.root = c_value; } else { c_value= event->xcrossing.root; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.root = c_value; } else { c_value= event->xkey.root; } break;
    case MotionNotify:
      if (value) { event->xmotion.root = c_value; } else { c_value= event->xmotion.root; } break;
    default: croak("Can't access XEvent.root for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_s(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ClientMessage:
      if (value) { { if (!SvPOK(value) || SvCUR(value) != sizeof(short)*10)  croak("Expected scalar of length %d but got %d", sizeof(short)*10, SvCUR(value)); memcpy(event->xclient.data.s, SvPVX(value), sizeof(short)*10);} } else { PUSHs(sv_2mortal(newSVpvn((void*)event->xclient.data.s, sizeof(short)*10))); } break;
    default: croak("Can't access XEvent.s for type=%d", event->type);
    }

void
_same_screen(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Bool c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.same_screen = c_value; } else { c_value= event->xbutton.same_screen; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.same_screen = c_value; } else { c_value= event->xcrossing.same_screen; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.same_screen = c_value; } else { c_value= event->xkey.same_screen; } break;
    case MotionNotify:
      if (value) { event->xmotion.same_screen = c_value; } else { c_value= event->xmotion.same_screen; } break;
    default: croak("Can't access XEvent.same_screen for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_selection(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.selection = c_value; } else { c_value= event->xselection.selection; } break;
    case SelectionClear:
      if (value) { event->xselectionclear.selection = c_value; } else { c_value= event->xselectionclear.selection; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.selection = c_value; } else { c_value= event->xselectionrequest.selection; } break;
    default: croak("Can't access XEvent.selection for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
send_event(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    if (value) {
      event->xany.send_event= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(event->xany.send_event)));
    }

void
serial(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    if (value) {
      event->xany.serial= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(event->xany.serial)));
    }

void
_state(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xbutton.state))); } break;
    case ColormapNotify:
      if (value) { event->xcolormap.state= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xcolormap.state))); } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xcrossing.state))); } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xkey.state))); } break;
    case MotionNotify:
      if (value) { event->xmotion.state= SvUV(value); } else { PUSHs(sv_2mortal(newSVuv(event->xmotion.state))); } break;
    case PropertyNotify:
      if (value) { event->xproperty.state= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xproperty.state))); } break;
    case VisibilityNotify:
      if (value) { event->xvisibility.state= SvIV(value); } else { PUSHs(sv_2mortal(newSViv(event->xvisibility.state))); } break;
    default: croak("Can't access XEvent.state for type=%d", event->type);
    }

void
_subwindow(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Window c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.subwindow = c_value; } else { c_value= event->xbutton.subwindow; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.subwindow = c_value; } else { c_value= event->xcrossing.subwindow; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.subwindow = c_value; } else { c_value= event->xkey.subwindow; } break;
    case MotionNotify:
      if (value) { event->xmotion.subwindow = c_value; } else { c_value= event->xmotion.subwindow; } break;
    default: croak("Can't access XEvent.subwindow for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_target(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Atom c_value= 0;
  PPCODE:
    if (value) { c_value= PerlXlib_sv_to_xid(value); }
    switch (event->type) {
    case SelectionNotify:
      if (value) { event->xselection.target = c_value; } else { c_value= event->xselection.target; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.target = c_value; } else { c_value= event->xselectionrequest.target; } break;
    default: croak("Can't access XEvent.target for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_time(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    Time c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.time = c_value; } else { c_value= event->xbutton.time; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.time = c_value; } else { c_value= event->xcrossing.time; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.time = c_value; } else { c_value= event->xkey.time; } break;
    case MotionNotify:
      if (value) { event->xmotion.time = c_value; } else { c_value= event->xmotion.time; } break;
    case PropertyNotify:
      if (value) { event->xproperty.time = c_value; } else { c_value= event->xproperty.time; } break;
    case SelectionNotify:
      if (value) { event->xselection.time = c_value; } else { c_value= event->xselection.time; } break;
    case SelectionClear:
      if (value) { event->xselectionclear.time = c_value; } else { c_value= event->xselectionclear.time; } break;
    case SelectionRequest:
      if (value) { event->xselectionrequest.time = c_value; } else { c_value= event->xselectionrequest.time; } break;
    default: croak("Can't access XEvent.time for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
type(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    const char *oldpkg, *newpkg;
  PPCODE:
    if (value) {
      if (event->type != SvIV(value)) {
        oldpkg= PerlXlib_xevent_pkg_for_type(event->type);
        event->type= SvIV(value);
        newpkg= PerlXlib_xevent_pkg_for_type(event->type);
        if (oldpkg != newpkg) {
          // re-initialize all fields in the area that changed
          memset( ((char*)(void*)event) + sizeof(XAnyEvent), 0, sizeof(XEvent)-sizeof(XAnyEvent) );
          // re-bless the object if the thing passed to us was actually an object
          if (sv_derived_from(ST(0), "X11::Xlib::XEvent"))
            sv_bless(ST(0), gv_stashpv(newpkg, GV_ADD));
        }
      }
    }
    PUSHs(sv_2mortal(newSViv(event->type)));

void
_value_mask(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    unsigned long c_value= 0;
  PPCODE:
    if (value) { c_value= SvUV(value); }
    switch (event->type) {
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.value_mask = c_value; } else { c_value= event->xconfigurerequest.value_mask; } break;
    default: croak("Can't access XEvent.value_mask for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSVuv(c_value)));

void
_width(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ConfigureNotify:
      if (value) { event->xconfigure.width = c_value; } else { c_value= event->xconfigure.width; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.width = c_value; } else { c_value= event->xconfigurerequest.width; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.width = c_value; } else { c_value= event->xcreatewindow.width; } break;
    case Expose:
      if (value) { event->xexpose.width = c_value; } else { c_value= event->xexpose.width; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.width = c_value; } else { c_value= event->xgraphicsexpose.width; } break;
    case ResizeRequest:
      if (value) { event->xresizerequest.width = c_value; } else { c_value= event->xresizerequest.width; } break;
    default: croak("Can't access XEvent.width for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
window(event, value=NULL)
  XEvent *event
  SV *value
  PPCODE:
    if (value) {
      event->xany.window= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(event->xany.window)));
    }

void
_x(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.x = c_value; } else { c_value= event->xbutton.x; } break;
    case ConfigureNotify:
      if (value) { event->xconfigure.x = c_value; } else { c_value= event->xconfigure.x; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.x = c_value; } else { c_value= event->xconfigurerequest.x; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.x = c_value; } else { c_value= event->xcreatewindow.x; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.x = c_value; } else { c_value= event->xcrossing.x; } break;
    case Expose:
      if (value) { event->xexpose.x = c_value; } else { c_value= event->xexpose.x; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.x = c_value; } else { c_value= event->xgraphicsexpose.x; } break;
    case GravityNotify:
      if (value) { event->xgravity.x = c_value; } else { c_value= event->xgravity.x; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.x = c_value; } else { c_value= event->xkey.x; } break;
    case MotionNotify:
      if (value) { event->xmotion.x = c_value; } else { c_value= event->xmotion.x; } break;
    case ReparentNotify:
      if (value) { event->xreparent.x = c_value; } else { c_value= event->xreparent.x; } break;
    default: croak("Can't access XEvent.x for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_x_root(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.x_root = c_value; } else { c_value= event->xbutton.x_root; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.x_root = c_value; } else { c_value= event->xcrossing.x_root; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.x_root = c_value; } else { c_value= event->xkey.x_root; } break;
    case MotionNotify:
      if (value) { event->xmotion.x_root = c_value; } else { c_value= event->xmotion.x_root; } break;
    default: croak("Can't access XEvent.x_root for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_y(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.y = c_value; } else { c_value= event->xbutton.y; } break;
    case ConfigureNotify:
      if (value) { event->xconfigure.y = c_value; } else { c_value= event->xconfigure.y; } break;
    case ConfigureRequest:
      if (value) { event->xconfigurerequest.y = c_value; } else { c_value= event->xconfigurerequest.y; } break;
    case CreateNotify:
      if (value) { event->xcreatewindow.y = c_value; } else { c_value= event->xcreatewindow.y; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.y = c_value; } else { c_value= event->xcrossing.y; } break;
    case Expose:
      if (value) { event->xexpose.y = c_value; } else { c_value= event->xexpose.y; } break;
    case GraphicsExpose:
      if (value) { event->xgraphicsexpose.y = c_value; } else { c_value= event->xgraphicsexpose.y; } break;
    case GravityNotify:
      if (value) { event->xgravity.y = c_value; } else { c_value= event->xgravity.y; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.y = c_value; } else { c_value= event->xkey.y; } break;
    case MotionNotify:
      if (value) { event->xmotion.y = c_value; } else { c_value= event->xmotion.y; } break;
    case ReparentNotify:
      if (value) { event->xreparent.y = c_value; } else { c_value= event->xreparent.y; } break;
    default: croak("Can't access XEvent.y for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

void
_y_root(event, value=NULL)
  XEvent *event
  SV *value
  INIT:
    int c_value= 0;
  PPCODE:
    if (value) { c_value= SvIV(value); }
    switch (event->type) {
    case ButtonPress:
    case ButtonRelease:
      if (value) { event->xbutton.y_root = c_value; } else { c_value= event->xbutton.y_root; } break;
    case EnterNotify:
    case LeaveNotify:
      if (value) { event->xcrossing.y_root = c_value; } else { c_value= event->xcrossing.y_root; } break;
    case KeyPress:
    case KeyRelease:
      if (value) { event->xkey.y_root = c_value; } else { c_value= event->xkey.y_root; } break;
    case MotionNotify:
      if (value) { event->xmotion.y_root = c_value; } else { c_value= event->xmotion.y_root; } break;
    default: croak("Can't access XEvent.y_root for type=%d", event->type);
    }
    PUSHs(value? value : sv_2mortal(newSViv(c_value)));

# END GENERATED X11_Xlib_XEvent
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XVisualInfo

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XVisualInfo

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XVisualInfo);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XVisualInfo", sizeof(XVisualInfo),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XVisualInfo_pack
        );
        memset((void*) sptr, 0, sizeof(XVisualInfo));

void
_pack(s, fields, consume=0)
    XVisualInfo *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XVisualInfo_pack(s, fields, consume);

void
_unpack(s, fields)
    XVisualInfo *s
    HV *fields
    PPCODE:
        PerlXlib_XVisualInfo_unpack(s, fields);

void
bits_per_rgb(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->bits_per_rgb= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->bits_per_rgb)));
    }

void
blue_mask(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->blue_mask= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->blue_mask)));
    }

void
class(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->class= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->class)));
    }

void
colormap_size(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->colormap_size= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->colormap_size)));
    }

void
depth(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->depth= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->depth)));
    }

void
green_mask(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->green_mask= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->green_mask)));
    }

void
red_mask(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->red_mask= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->red_mask)));
    }

void
screen(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->screen= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->screen)));
    }

void
visual(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      { if (SvOK(value) && !sv_isa(value, "X11::Xlib::Visual"))  croak("Expected X11::Xlib::Visual"); s->visual= SvOK(value)? (Visual *) SvIV((SV*)SvRV(value)) : NULL;}
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal((s->visual? sv_setref_pv(newSV(0), "X11::Xlib::Visual", (void*) s->visual) : &PL_sv_undef)));
    }

void
visualid(s, value=NULL)
    XVisualInfo *s
    SV *value
  PPCODE:
    if (value) {
      s->visualid= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->visualid)));
    }

# END GENERATED X11_Xlib_XVisualInfo
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XSetWindowAttributes

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XSetWindowAttributes

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XSetWindowAttributes);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XSetWindowAttributes", sizeof(XSetWindowAttributes),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XSetWindowAttributes_pack
        );
        memset((void*) sptr, 0, sizeof(XSetWindowAttributes));

void
_pack(s, fields, consume=0)
    XSetWindowAttributes *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XSetWindowAttributes_pack(s, fields, consume);

void
_unpack(s, fields)
    XSetWindowAttributes *s
    HV *fields
    PPCODE:
        PerlXlib_XSetWindowAttributes_unpack(s, fields);

void
background_pixel(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->background_pixel= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->background_pixel)));
    }

void
background_pixmap(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->background_pixmap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->background_pixmap)));
    }

void
backing_pixel(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->backing_pixel= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->backing_pixel)));
    }

void
backing_planes(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->backing_planes= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->backing_planes)));
    }

void
backing_store(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->backing_store= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->backing_store)));
    }

void
bit_gravity(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->bit_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->bit_gravity)));
    }

void
border_pixel(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->border_pixel= SvUV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->border_pixel)));
    }

void
border_pixmap(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->border_pixmap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->border_pixmap)));
    }

void
colormap(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->colormap= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->colormap)));
    }

void
cursor(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->cursor= PerlXlib_sv_to_xid(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSVuv(s->cursor)));
    }

void
do_not_propagate_mask(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->do_not_propagate_mask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->do_not_propagate_mask)));
    }

void
event_mask(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->event_mask= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->event_mask)));
    }

void
override_redirect(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->override_redirect= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->override_redirect)));
    }

void
save_under(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->save_under= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->save_under)));
    }

void
win_gravity(s, value=NULL)
    XSetWindowAttributes *s
    SV *value
  PPCODE:
    if (value) {
      s->win_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->win_gravity)));
    }

# END GENERATED X11_Xlib_XSetWindowAttributes
# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XSizeHints

MODULE = X11::Xlib                PACKAGE = X11::Xlib::XSizeHints

int
_sizeof(ignored=NULL)
    SV* ignored;
    CODE:
        RETVAL = sizeof(XSizeHints);
    OUTPUT:
        RETVAL

void
_initialize(s)
    SV *s
    INIT:
        void *sptr;
    PPCODE:
        sptr= PerlXlib_get_struct_ptr(s, 1, "X11::Xlib::XSizeHints", sizeof(XSizeHints),
            (PerlXlib_struct_pack_fn*) &PerlXlib_XSizeHints_pack
        );
        memset((void*) sptr, 0, sizeof(XSizeHints));

void
_pack(s, fields, consume=0)
    XSizeHints *s
    HV *fields
    Bool consume
    PPCODE:
        PerlXlib_XSizeHints_pack(s, fields, consume);

void
_unpack(s, fields)
    XSizeHints *s
    HV *fields
    PPCODE:
        PerlXlib_XSizeHints_unpack(s, fields);

void
base_height(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->base_height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->base_height)));
    }

void
base_width(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->base_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->base_width)));
    }

void
flags(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->flags= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->flags)));
    }

void
height(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->height)));
    }

void
height_inc(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->height_inc= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->height_inc)));
    }

void
max_aspect_x(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->max_aspect.x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_aspect.x)));
    }

void
max_aspect_y(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->max_aspect.y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_aspect.y)));
    }

void
max_height(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->max_height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_height)));
    }

void
max_width(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->max_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->max_width)));
    }

void
min_aspect_x(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->min_aspect.x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_aspect.x)));
    }

void
min_aspect_y(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->min_aspect.y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_aspect.y)));
    }

void
min_height(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->min_height= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_height)));
    }

void
min_width(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->min_width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->min_width)));
    }

void
width(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->width= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->width)));
    }

void
width_inc(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->width_inc= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->width_inc)));
    }

void
win_gravity(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->win_gravity= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->win_gravity)));
    }

void
x(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->x= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->x)));
    }

void
y(s, value=NULL)
    XSizeHints *s
    SV *value
  PPCODE:
    if (value) {
      s->y= SvIV(value);
      PUSHs(value);
    } else {
      PUSHs(sv_2mortal(newSViv(s->y)));
    }

# END GENERATED X11_Xlib_XSizeHints
# ----------------------------------------------------------------------------

BOOT:
# BEGIN GENERATED BOOT CONSTANTS
  HV* stash= gv_stashpvn("X11::Xlib", 9, 1);
  newCONSTSUB(stash, "ButtonPress", newSViv(ButtonPress));
  newCONSTSUB(stash, "ButtonRelease", newSViv(ButtonRelease));
  newCONSTSUB(stash, "CirculateNotify", newSViv(CirculateNotify));
  newCONSTSUB(stash, "ClientMessage", newSViv(ClientMessage));
  newCONSTSUB(stash, "ColormapNotify", newSViv(ColormapNotify));
  newCONSTSUB(stash, "ConfigureNotify", newSViv(ConfigureNotify));
  newCONSTSUB(stash, "CreateNotify", newSViv(CreateNotify));
  newCONSTSUB(stash, "DestroyNotify", newSViv(DestroyNotify));
  newCONSTSUB(stash, "EnterNotify", newSViv(EnterNotify));
  newCONSTSUB(stash, "Expose", newSViv(Expose));
  newCONSTSUB(stash, "FocusIn", newSViv(FocusIn));
  newCONSTSUB(stash, "FocusOut", newSViv(FocusOut));
  newCONSTSUB(stash, "GraphicsExpose", newSViv(GraphicsExpose));
  newCONSTSUB(stash, "GravityNotify", newSViv(GravityNotify));
  newCONSTSUB(stash, "KeyPress", newSViv(KeyPress));
  newCONSTSUB(stash, "KeyRelease", newSViv(KeyRelease));
  newCONSTSUB(stash, "KeymapNotify", newSViv(KeymapNotify));
  newCONSTSUB(stash, "LeaveNotify", newSViv(LeaveNotify));
  newCONSTSUB(stash, "MapNotify", newSViv(MapNotify));
  newCONSTSUB(stash, "MappingNotify", newSViv(MappingNotify));
  newCONSTSUB(stash, "MotionNotify", newSViv(MotionNotify));
  newCONSTSUB(stash, "NoExpose", newSViv(NoExpose));
  newCONSTSUB(stash, "PropertyNotify", newSViv(PropertyNotify));
  newCONSTSUB(stash, "ReparentNotify", newSViv(ReparentNotify));
  newCONSTSUB(stash, "ResizeRequest", newSViv(ResizeRequest));
  newCONSTSUB(stash, "SelectionClear", newSViv(SelectionClear));
  newCONSTSUB(stash, "SelectionNotify", newSViv(SelectionNotify));
  newCONSTSUB(stash, "SelectionRequest", newSViv(SelectionRequest));
  newCONSTSUB(stash, "UnmapNotify", newSViv(UnmapNotify));
  newCONSTSUB(stash, "VisibilityNotify", newSViv(VisibilityNotify));
  newCONSTSUB(stash, "NoEventMask", newSViv(NoEventMask));
  newCONSTSUB(stash, "KeyPressMask", newSViv(KeyPressMask));
  newCONSTSUB(stash, "KeyReleaseMask", newSViv(KeyReleaseMask));
  newCONSTSUB(stash, "ButtonPressMask", newSViv(ButtonPressMask));
  newCONSTSUB(stash, "ButtonReleaseMask", newSViv(ButtonReleaseMask));
  newCONSTSUB(stash, "EnterWindowMask", newSViv(EnterWindowMask));
  newCONSTSUB(stash, "LeaveWindowMask", newSViv(LeaveWindowMask));
  newCONSTSUB(stash, "PointerMotionMask", newSViv(PointerMotionMask));
  newCONSTSUB(stash, "PointerMotionHintMask", newSViv(PointerMotionHintMask));
  newCONSTSUB(stash, "Button1MotionMask", newSViv(Button1MotionMask));
  newCONSTSUB(stash, "Button2MotionMask", newSViv(Button2MotionMask));
  newCONSTSUB(stash, "Button3MotionMask", newSViv(Button3MotionMask));
  newCONSTSUB(stash, "Button4MotionMask", newSViv(Button4MotionMask));
  newCONSTSUB(stash, "Button5MotionMask", newSViv(Button5MotionMask));
  newCONSTSUB(stash, "ButtonMotionMask", newSViv(ButtonMotionMask));
  newCONSTSUB(stash, "KeymapStateMask", newSViv(KeymapStateMask));
  newCONSTSUB(stash, "ExposureMask", newSViv(ExposureMask));
  newCONSTSUB(stash, "VisibilityChangeMask", newSViv(VisibilityChangeMask));
  newCONSTSUB(stash, "StructureNotifyMask", newSViv(StructureNotifyMask));
  newCONSTSUB(stash, "ResizeRedirectMask", newSViv(ResizeRedirectMask));
  newCONSTSUB(stash, "SubstructureNotifyMask", newSViv(SubstructureNotifyMask));
  newCONSTSUB(stash, "SubstructureRedirectMask", newSViv(SubstructureRedirectMask));
  newCONSTSUB(stash, "FocusChangeMask", newSViv(FocusChangeMask));
  newCONSTSUB(stash, "PropertyChangeMask", newSViv(PropertyChangeMask));
  newCONSTSUB(stash, "ColormapChangeMask", newSViv(ColormapChangeMask));
  newCONSTSUB(stash, "OwnerGrabButtonMask", newSViv(OwnerGrabButtonMask));
  newCONSTSUB(stash, "ShiftMask", newSViv(ShiftMask));
  newCONSTSUB(stash, "LockMask", newSViv(LockMask));
  newCONSTSUB(stash, "ControlMask", newSViv(ControlMask));
  newCONSTSUB(stash, "Mod1Mask", newSViv(Mod1Mask));
  newCONSTSUB(stash, "Mod2Mask", newSViv(Mod2Mask));
  newCONSTSUB(stash, "Mod3Mask", newSViv(Mod3Mask));
  newCONSTSUB(stash, "Mod4Mask", newSViv(Mod4Mask));
  newCONSTSUB(stash, "Mod5Mask", newSViv(Mod5Mask));
  newCONSTSUB(stash, "Button1Mask", newSViv(Button1Mask));
  newCONSTSUB(stash, "Button2Mask", newSViv(Button2Mask));
  newCONSTSUB(stash, "Button3Mask", newSViv(Button3Mask));
  newCONSTSUB(stash, "Button4Mask", newSViv(Button4Mask));
  newCONSTSUB(stash, "Button5Mask", newSViv(Button5Mask));
  newCONSTSUB(stash, "BadAccess", newSViv(BadAccess));
  newCONSTSUB(stash, "BadAlloc", newSViv(BadAlloc));
  newCONSTSUB(stash, "BadAtom", newSViv(BadAtom));
  newCONSTSUB(stash, "BadColor", newSViv(BadColor));
  newCONSTSUB(stash, "BadCursor", newSViv(BadCursor));
  newCONSTSUB(stash, "BadDrawable", newSViv(BadDrawable));
  newCONSTSUB(stash, "BadFont", newSViv(BadFont));
  newCONSTSUB(stash, "BadGC", newSViv(BadGC));
  newCONSTSUB(stash, "BadIDChoice", newSViv(BadIDChoice));
  newCONSTSUB(stash, "BadImplementation", newSViv(BadImplementation));
  newCONSTSUB(stash, "BadLength", newSViv(BadLength));
  newCONSTSUB(stash, "BadMatch", newSViv(BadMatch));
  newCONSTSUB(stash, "BadName", newSViv(BadName));
  newCONSTSUB(stash, "BadPixmap", newSViv(BadPixmap));
  newCONSTSUB(stash, "BadRequest", newSViv(BadRequest));
  newCONSTSUB(stash, "BadValue", newSViv(BadValue));
  newCONSTSUB(stash, "BadWindow", newSViv(BadWindow));
  newCONSTSUB(stash, "VisualIDMask", newSViv(VisualIDMask));
  newCONSTSUB(stash, "VisualScreenMask", newSViv(VisualScreenMask));
  newCONSTSUB(stash, "VisualDepthMask", newSViv(VisualDepthMask));
  newCONSTSUB(stash, "VisualClassMask", newSViv(VisualClassMask));
  newCONSTSUB(stash, "VisualRedMaskMask", newSViv(VisualRedMaskMask));
  newCONSTSUB(stash, "VisualGreenMaskMask", newSViv(VisualGreenMaskMask));
  newCONSTSUB(stash, "VisualBlueMaskMask", newSViv(VisualBlueMaskMask));
  newCONSTSUB(stash, "VisualColormapSizeMask", newSViv(VisualColormapSizeMask));
  newCONSTSUB(stash, "VisualBitsPerRGBMask", newSViv(VisualBitsPerRGBMask));
  newCONSTSUB(stash, "VisualAllMask", newSViv(VisualAllMask));
  newCONSTSUB(stash, "AllocAll", newSViv(AllocAll));
  newCONSTSUB(stash, "AllocNone", newSViv(AllocNone));
  newCONSTSUB(stash, "InputOutput", newSViv(InputOutput));
  newCONSTSUB(stash, "InputOnly", newSViv(InputOnly));
  newCONSTSUB(stash, "CopyFromParent", newSViv(CopyFromParent));
  newCONSTSUB(stash, "CWBackPixmap", newSViv(CWBackPixmap));
  newCONSTSUB(stash, "CWBackPixel", newSViv(CWBackPixel));
  newCONSTSUB(stash, "CWBorderPixmap", newSViv(CWBorderPixmap));
  newCONSTSUB(stash, "CWBorderPixel", newSViv(CWBorderPixel));
  newCONSTSUB(stash, "CWBitGravity", newSViv(CWBitGravity));
  newCONSTSUB(stash, "CWWinGravity", newSViv(CWWinGravity));
  newCONSTSUB(stash, "CWBackingStore", newSViv(CWBackingStore));
  newCONSTSUB(stash, "CWBackingPlanes", newSViv(CWBackingPlanes));
  newCONSTSUB(stash, "CWBackingPixel", newSViv(CWBackingPixel));
  newCONSTSUB(stash, "CWOverrideRedirect", newSViv(CWOverrideRedirect));
  newCONSTSUB(stash, "CWSaveUnder", newSViv(CWSaveUnder));
  newCONSTSUB(stash, "CWEventMask", newSViv(CWEventMask));
  newCONSTSUB(stash, "CWDontPropagate", newSViv(CWDontPropagate));
  newCONSTSUB(stash, "CWColormap", newSViv(CWColormap));
  newCONSTSUB(stash, "CWCursor", newSViv(CWCursor));
  newCONSTSUB(stash, "USPosition", newSViv(USPosition));
  newCONSTSUB(stash, "USSize", newSViv(USSize));
  newCONSTSUB(stash, "PPosition", newSViv(PPosition));
  newCONSTSUB(stash, "PSize", newSViv(PSize));
  newCONSTSUB(stash, "PMinSize", newSViv(PMinSize));
  newCONSTSUB(stash, "PMaxSize", newSViv(PMaxSize));
  newCONSTSUB(stash, "PResizeInc", newSViv(PResizeInc));
  newCONSTSUB(stash, "PAspect", newSViv(PAspect));
  newCONSTSUB(stash, "PBaseSize", newSViv(PBaseSize));
  newCONSTSUB(stash, "PWinGravity", newSViv(PWinGravity));
# END GENERATED BOOT CONSTANTS
#