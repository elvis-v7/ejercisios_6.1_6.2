using System;
class Program
{
    static void Main()
    {
        // Cadenas de ADN
        string text1 = "ATCGGATTC";
        string text2 = "TAGCCTAAG";

        // Guardamos las cadenas y sus longitudes que se usaran para marcar los limites de la matriz
        int m = text1.Length;
        int n = text2.Length;

        // Creamos la matriz y agregamos columna extra para el caso base
        int[,] memo = new int[m + 1, n + 1];

        // Llenar la matriz con -1 indicando que aun no se calcula ya que 0 es un caso base
        for (int i = 0; i <= m; i++)
        {
            for (int j = 0; j <= n; j++)
            {
                memo[i, j] = -1;
            }
        }

        // Funcion recursiva obtenemos la longitud de la secuencia común más larga
        int longitud = Lcs(text1, text2, m, n, memo);

        // Reconstruir el texto respuesta hacia atrás
        string resultado = "";
        int x = m;
        int y = n;

        while (x > 0 && y > 0)
        {
            // Si los caracteres coinciden, esta letra es parte de la respuesta
            if (text1[x - 1] == text2[y - 1])
            {
                resultado = text1[x - 1] + resultado; // Guardamos la letra al inicio
                x--;
                y--;
            }
            // Si no coinciden, nos movemos al camino con el número más alto
            else if (memo[x - 1, y] >= memo[x, y - 1])
            {
                x--;
            }
            else
            {
                y--;
            }
        }

        Console.WriteLine("Texto 1: " + text1);
        Console.WriteLine("Texto 2: " + text2);
        Console.WriteLine("Longitud: " + longitud);
        Console.WriteLine("Secuencia: " + resultado);
    }

    // Función recursiva básica con memoización
    static int Lcs(string text1, string text2, int i, int j, int[,] memo)
    {
        // Caso base: si llegamos al inicio de algún texto, la coincidencia es 0
        if (i == 0 || j == 0)
        {
            return 0;
        }

        // Si ya calculamos este resultado antes, lo reutilizamos y se evitan calcularlo de nuevo
        if (memo[i, j] != -1)
        {
            return memo[i, j];
        }

        // Si la letra de text1 coincide con la letra de text2 sumamos 1 y seguimos con las letras siguientes
        if (text1[i - 1] == text2[j - 1])
        {
            memo[i, j] = 1 + Lcs(text1, text2, i - 1, j - 1, memo);
        }
        else
        {
            // Si no coinciden, probamos quitar una letra de text1 o una de text2
            int opcion1 = Lcs(text1, text2, i - 1, j, memo);
            int opcion2 = Lcs(text1, text2, i, j - 1, memo);

            // Guardar la opción más grande
            if (opcion1 > opcion2)
            {
                memo[i, j] = opcion1;
            }
            else
            {
                memo[i, j] = opcion2;
            }
        }

        return memo[i, j];
    }
}