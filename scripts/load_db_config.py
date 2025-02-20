


from configparser import ConfigParser

def load_db_config(filename='db_config.ini', section='postgresql'):
    """
    Load database configuration from an .ini file.
    Returns a dictionary of parameters for psycopg2.
    """
    # example 'db_config.ini'
    # [postgresql]
    # host = 1.2.3.4
    # port = 5432
    # database = vhf
    # user = add-user-here
    # password = add-password-here

    parser = ConfigParser()
    parser.read(filename)

    if not parser.has_section(section):
        raise Exception(f"Section {section} not found in the {filename} file.")

    db_config = {}
    for param in parser.items(section):
        db_config[param[0]] = param[1]

    return db_config
