MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Type

ffi_pl_type *
_new(class, type, fuzzy_type, array_or_record_or_string_size, type_classname, rw)
    const char *class
    const char *type
    const char *fuzzy_type
    size_t array_or_record_or_string_size
    ffi_pl_string type_classname
    int rw
  PREINIT:
    ffi_pl_type *self;
    dMY_CXT;
  CODE:
    (void)class;
    self = NULL;
    if(!strcmp(fuzzy_type, "string"))
    {
      self = ffi_pl_type_new(0);
      self->type_code |= FFI_PL_TYPE_STRING;
      self->sub_type = rw ? FFI_PL_TYPE_STRING_RW : FFI_PL_TYPE_STRING_RO;
    }
    else if(!strcmp(fuzzy_type, "ffi"))
    {
      self = ffi_pl_type_new(0);
      if(!strcmp(type, "longdouble"))
      {
        self->type_code |= FFI_PL_TYPE_LONG_DOUBLE;
        if(MY_CXT.have_math_longdouble == -1)
          MY_CXT.have_math_longdouble = have_pm("Math::LongDouble");
      }
      else if(!strcmp(type, "complex_float"))
      {
        self->type_code |= FFI_PL_TYPE_COMPLEX_FLOAT;
        if(MY_CXT.have_math_complex == -1)
          MY_CXT.have_math_complex = have_pm("Math::Complex");
      }
      else if(!strcmp(type, "complex_double"))
      {
        self->type_code |= FFI_PL_TYPE_COMPLEX_DOUBLE;
        if(MY_CXT.have_math_complex == -1)
          MY_CXT.have_math_complex = have_pm("Math::Complex");
      }
    }
    else if(!strcmp(fuzzy_type, "pointer"))
    {
      self = ffi_pl_type_new(0);
      self->type_code |= FFI_PL_SHAPE_POINTER;
    }
    else if(!strcmp(fuzzy_type, "array"))
    {
      self = ffi_pl_type_new(sizeof(ffi_pl_type_extra_array));
      self->type_code |= FFI_PL_SHAPE_ARRAY;
      self->extra[0].array.element_count = array_or_record_or_string_size;
    }
    else if(!strcmp(fuzzy_type, "record"))
    {
      self = ffi_pl_type_new(sizeof(ffi_pl_type_extra_record));
      self->type_code |= FFI_PL_TYPE_RECORD;
      self->extra[0].record.size = array_or_record_or_string_size;
      self->extra[0].record.stash = type_classname != NULL ? gv_stashpv(type_classname, GV_ADD) : NULL;
    }
    else
    {
      croak("unknown ffi/platypus type: %s/%s", type, fuzzy_type);
    }

    int type_code = ffi_pl_name_to_code(type);
    if(type_code == -1)
    {
      Safefree(self);
      self = NULL;
      croak("unknown ffi/platypus type: %s/%s", type, fuzzy_type);
    }
    self->type_code |= type_code;

    RETVAL = self;
  OUTPUT:
    RETVAL

ffi_pl_type *
_new_custom_perl(class, type, perl_to_native, native_to_perl, perl_to_native_post, argument_count)
    const char *class
    const char *type
    SV *perl_to_native
    SV *native_to_perl
    SV *perl_to_native_post
    int argument_count
  PREINIT:
    ffi_pl_type *self;
    ffi_pl_type_extra_custom_perl *custom;
    int type_code;
  CODE:
    (void)class;
    type_code = ffi_pl_name_to_code(type);
    if(type_code == -1)
      croak("unknown ffi/platypus type: %s/custom", type);
    
    self = ffi_pl_type_new(sizeof(ffi_pl_type_extra_custom_perl));  
    self->type_code = FFI_PL_SHAPE_CUSTOM_PERL | type_code;
    
    custom = &self->extra[0].custom_perl;
    custom->perl_to_native = SvOK(perl_to_native) ? SvREFCNT_inc_simple_NN(perl_to_native) : NULL;
    custom->perl_to_native_post = SvOK(perl_to_native_post) ? SvREFCNT_inc_simple_NN(perl_to_native_post) : NULL;
    custom->native_to_perl = SvOK(native_to_perl) ? SvREFCNT_inc_simple_NN(native_to_perl) : NULL;
    custom->argument_count = argument_count-1;
    
    RETVAL = self;
  OUTPUT:
    RETVAL


ffi_pl_type *
_new_closure(class, return_type, ...)
    const char *class;
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_type *self;
    int i;
    SV *arg;
    ffi_type *ffi_return_type;
    ffi_type **ffi_argument_types;
    ffi_status ffi_status;
  CODE:
    (void)class;
    switch(return_type->type_code)
    {
      case FFI_PL_TYPE_VOID:
      case FFI_PL_TYPE_SINT8:
      case FFI_PL_TYPE_SINT16:
      case FFI_PL_TYPE_SINT32:
      case FFI_PL_TYPE_SINT64:
      case FFI_PL_TYPE_UINT8:
      case FFI_PL_TYPE_UINT16:
      case FFI_PL_TYPE_UINT32:
      case FFI_PL_TYPE_UINT64:
      case FFI_PL_TYPE_FLOAT:
      case FFI_PL_TYPE_DOUBLE:
      case FFI_PL_TYPE_OPAQUE:
        break;
      default:
        croak("Only native types are supported as closure return types");
        break;
    }
    
    for(i=0; i<(items-2); i++)
    {
      arg = ST(2+i);
      ffi_pl_type *arg_type = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(arg)));
      switch(arg_type->type_code)
      {
        case FFI_PL_TYPE_VOID:
        case FFI_PL_TYPE_SINT8:
        case FFI_PL_TYPE_SINT16:
        case FFI_PL_TYPE_SINT32:
        case FFI_PL_TYPE_SINT64:
        case FFI_PL_TYPE_UINT8:
        case FFI_PL_TYPE_UINT16:
        case FFI_PL_TYPE_UINT32:
        case FFI_PL_TYPE_UINT64:
        case FFI_PL_TYPE_FLOAT:
        case FFI_PL_TYPE_DOUBLE:
        case FFI_PL_TYPE_OPAQUE:
        case FFI_PL_TYPE_STRING:
        case FFI_PL_TYPE_RECORD:
          break;
        default:
          croak("Only native types and strings are supported as closure argument types");
          break;
      } 
    }
    
    Newx(ffi_argument_types, items-2, ffi_type*);
    self = ffi_pl_type_new(sizeof(ffi_pl_type_extra_closure) + sizeof(ffi_pl_type)*(items-2));
    self->type_code = FFI_PL_TYPE_CLOSURE;
    
    self->extra[0].closure.return_type = return_type;
    self->extra[0].closure.flags = 0;
    
    ffi_return_type = ffi_pl_type_to_libffi_type(return_type);
    
    for(i=0; i<(items-2); i++)
    {
      arg = ST(2+i);
      self->extra[0].closure.argument_types[i] = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(arg)));
      ffi_argument_types[i] = ffi_pl_type_to_libffi_type(self->extra[0].closure.argument_types[i]);
    }
    
    ffi_status = ffi_prep_cif(
      &self->extra[0].closure.ffi_cif,
      FFI_DEFAULT_ABI,
      items-2,
      ffi_return_type,
      ffi_argument_types
    );
    
    if(ffi_status != FFI_OK)
    {
      Safefree(self);
      Safefree(ffi_argument_types);
      if(ffi_status == FFI_BAD_TYPEDEF)
        croak("bad typedef");
      else if(ffi_status == FFI_BAD_ABI)
        croak("bad abi");
      else
        croak("unknown error with ffi_prep_cif");
    }

    if( items-2 == 0 )
    {
      self->extra[0].closure.flags |= G_NOARGS;
    }
    
    if(self->extra[0].closure.return_type->type_code == FFI_PL_TYPE_VOID)
    {
      self->extra[0].closure.flags |= G_DISCARD | G_VOID;
    }
    else
    {
      self->extra[0].closure.flags |= G_SCALAR;
    }
    
    RETVAL = self;
    
  OUTPUT:
    RETVAL

SV*
meta(self)
    ffi_pl_type *self
  PREINIT:
    HV *meta;
  CODE:
    meta = ffi_pl_get_type_meta(self);
    RETVAL = newRV_noinc((SV*)meta);
  OUTPUT:
    RETVAL

int
sizeof(self)
    ffi_pl_type *self
  CODE:
    RETVAL = ffi_pl_sizeof(self);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_type *self
  CODE:
    if(self->type_code == FFI_PL_TYPE_CLOSURE)
    {
      if(!PL_dirty)
        Safefree(self->extra[0].closure.ffi_cif.arg_types);
    }
    else if((self->type_code & FFI_PL_SHAPE_MASK) == FFI_PL_SHAPE_CUSTOM_PERL)
    {
      ffi_pl_type_extra_custom_perl *custom;
      
      custom = &self->extra[0].custom_perl;
      
      if(custom->perl_to_native != NULL)
        SvREFCNT_dec(custom->perl_to_native);
      if(custom->perl_to_native_post != NULL)
        SvREFCNT_dec(custom->perl_to_native_post);
      if(custom->native_to_perl != NULL)
        SvREFCNT_dec(custom->native_to_perl);
    }
    if(!PL_dirty)
      Safefree(self);

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Type::StringPointer

void
native_to_perl_xs(pointer)
    SV *pointer
  PREINIT:
    const char **string_c;
    SV *string_perl;
  CODE:
    /* we currently use the pp version instead */
    if(SvOK(pointer))
    {
      string_c = INT2PTR(const char**,SvIV(pointer));
      if(*string_c != NULL)
      {
        string_perl = sv_newmortal();
        sv_setpv(string_perl, *string_c);
        ST(0) = newRV_inc(string_perl);
      }
      else
      {
        ST(0) = newRV_noinc(&PL_sv_undef);
      }
      XSRETURN(1);
    }
    else
    {
      XSRETURN_EMPTY;
    }
