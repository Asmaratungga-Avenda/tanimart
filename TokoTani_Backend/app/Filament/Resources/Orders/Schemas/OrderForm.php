<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Models\Courier;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('nama_penerima')
                    ->label('Nama Penerima')
                    ->disabled(),
                Textarea::make('alamat_penerima')
                    ->label('Alamat Penerima')
                    ->disabled()
                    ->columnSpanFull(),
                Select::make('kurir_id')
                    ->label('Kurir')
                    ->relationship('courier', 'nama')
                    ->disabled(),
                Select::make('payment_method_id')
                    ->label('Metode Pembayaran')
                    ->relationship('paymentMethod', 'nama')
                    ->disabled(),
                DatePicker::make('tanggal_antar')
                    ->label('Tanggal Pengantaran')
                    ->disabled(),
                Select::make('status')
                    ->label('Status Pesanan')
                    ->options([
                        'menunggu_pembayaran' => 'Menunggu Pembayaran',
                        'diproses' => 'Diproses',
                        'dikirim' => 'Dikirim',
                        'tiba' => 'Tiba',
                        'selesai' => 'Selesai',
                        'dibatalkan' => 'Dibatalkan',
                    ])
                    ->disabled(),
                TextInput::make('subtotal')
                    ->label('Subtotal')
                    ->numeric()
                    ->prefix('Rp')
                    ->disabled(),
                TextInput::make('ongkir')
                    ->label('Ongkos Kirim')
                    ->numeric()
                    ->prefix('Rp')
                    ->disabled(),
                TextInput::make('total_harga')
                    ->label('Total Harga')
                    ->numeric()
                    ->prefix('Rp')
                    ->disabled(),
                TextInput::make('idempotency_key')
                    ->label('Idempotency Key')
                    ->disabled()
                    ->columnSpanFull(),
            ]);
    }
}
