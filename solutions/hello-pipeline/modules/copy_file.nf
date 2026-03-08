process copy_file {

    input:
        path cowpy_file

    output:
        path 'copied_cowpy.txt'
        
    script:
        """
        cp ${cowpy_file} copied_cowpy.txt
        """
    }