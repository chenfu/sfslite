
// -*-c++-*-

#ifndef __PY_UTIL_H_INCLUDED__
#define __PY_UTIL_H_INCLUDED__

template<class T> str
safe_to_str (const T *in)
{
  strbuf b;
  rpc_print (b, *in);
  PyErr_Clear ();
  return b;
}


template<class T> PyObject *
pretty_print_to_py_str_obj (const T *in)
{
  str s = safe_to_str (in);
  return PyString_FromFormat (s.cstr ());
}

template<class T> int
pretty_print_to_fd (const T *in, FILE *fp)
{
  str s = safe_to_str (in);
  if (s[s.len () - 1] == '\n') {
    mstr m (s.len ());
    strcpy (m.cstr (), s.cstr ());
    m[m.len () - 1] = '\0';
    m.setlen (m.len () - 1);
    s = m;
  }
    
  fputs (s.cstr (), fp);
  return 0;
}


#endif
